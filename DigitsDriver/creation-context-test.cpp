// Host-only behavioral checks. This executable has no IOKit or kernel linkage.
#include "CreationContext.hpp"
#include <cstdio>
#include <cstdlib>
#include <vector>

static size_t checks;
static void expect(bool result, const char* message)
{
    ++checks;
    if (!result) { std::fprintf(stderr, "FAIL: %s\n", message); std::exit(1); }
}

static constexpr uintptr_t kController = 0x1000;
static constexpr uint32_t kSpeed = 3, kRoute = 0x2100000, kOptions = 0x10;
using Contexts = XeneonCreationContexts;
static bool claim(Contexts& c, uintptr_t thread = 1)
{ return c.claim(thread, kController, kSpeed, kOptions, kRoute); }
static Contexts::Token push(Contexts& c, uintptr_t thread = 1)
{ return c.push(thread, kController, kSpeed, kRoute, kOptions); }

int main()
{
    {
        Contexts c;
        expect(!claim(c), "an inner call without its outer context cannot select");
        auto t = push(c);
        expect(t.valid, "matching outer call has context");
        expect(!c.claim(1, kController + 1, kSpeed, kOptions, kRoute), "wrong controller fails");
        expect(!c.claim(1, kController, kSpeed + 1, kOptions, kRoute), "wrong speed fails");
        expect(!c.claim(1, kController, kSpeed, kOptions + 2, kRoute), "wrong options fail");
        expect(!c.claim(1, kController, kSpeed, kOptions, kRoute + 1), "wrong physical route fails");
        expect(!claim(c, 2), "different thread cannot borrow context");
        expect(claim(c), "rejected mismatches do not consume correct context");
        expect(!claim(c), "selection is consumed once per outer call");
        c.pop(t);
        expect(!claim(c), "completed creation leaves no reusable route");
    }
    {
        Contexts c;
        auto outer = push(c);
        auto foreign = c.push(1, kController, kSpeed, kRoute + 1, kOptions);
        expect(!claim(c), "nested unrelated route hides eligible parent");
        c.pop(foreign);
        expect(claim(c), "normal unwind restores unconsumed parent");
        auto nested = push(c);
        expect(claim(c), "nested matching call owns independent selection");
        c.pop(nested);
        expect(!claim(c), "popping child does not reset consumed parent");
        c.pop(outer);
        auto embedded = c.push(1, kController, kSpeed, kRoute, kOptions | 1);
        expect(!c.claim(1, kController, kSpeed, kOptions | 1, kRoute), "embedded-device option is never selected");
        c.pop(embedded);
    }
    {
        Contexts c;
        std::vector<Contexts::Token> normal, overflow;
        for (size_t i = 0; i < Contexts::kDepth; ++i) normal.push_back(push(c));
        for (size_t i = 0; i < 128; ++i) {
            overflow.push_back(c.push(1, kController + i + 1, kSpeed, kRoute + 1, kOptions));
            expect(overflow.back().valid && overflow.back().overflow, "depth overflow has balanced suppression token");
            expect(!claim(c), "overflow never exposes eligible parent");
        }
        while (!overflow.empty()) {
            expect(!claim(c), "suppression persists until final overflow unwind");
            c.pop(overflow.back()); overflow.pop_back();
        }
        expect(claim(c), "fully unwound overflow restores top saved frame");
        while (!normal.empty()) { c.pop(normal.back()); normal.pop_back(); }
        expect(!claim(c), "full depth unwind removes thread context");
    }
    {
        Contexts c;
        std::vector<Contexts::Token> tokens;
        for (uintptr_t thread = 1; thread <= Contexts::kThreadCount; ++thread) tokens.push_back(push(c, thread));
        auto full = push(c, 99);
        expect(!full.valid, "thread-table exhaustion rejects the new thread");
        expect(!claim(c, 99), "rejected new thread cannot inherit another thread route");
        auto nested = c.push(1, kController, kSpeed, kRoute + 1, kOptions);
        expect(nested.valid && !claim(c), "existing thread still suppresses nested foreign route when table is full");
        c.pop(nested);
        for (uintptr_t thread = 1; thread <= Contexts::kThreadCount; ++thread) {
            expect(claim(c, thread), "each occupied thread owns only its selection");
            c.pop(tokens[thread - 1]);
        }
        for (uintptr_t thread = 100; thread < 356; ++thread) {
            auto reused = push(c, thread);
            expect(reused.valid && claim(c, thread), "finished thread slots can be reused without stale consumption");
            c.pop(reused);
        }
    }
    {
        Contexts c;
        auto parent = push(c);
        auto child = push(c);
        c.pop(parent); // Caller invariant broken: older token cannot pop child.
        expect(!claim(c), "out-of-order unwind permanently fails closed for that live bucket");
        c.pop(child);
        c.pop(parent);
        auto later = push(c);
        expect(!claim(c), "broken unwind cannot authorize a later creation on poisoned thread");
        c.pop(later);
        expect(!c.push(0, kController, kSpeed, kRoute, kOptions).valid, "null thread rejected");
        expect(!c.push(2, 0, kSpeed, kRoute, kOptions).valid, "null controller rejected");
    }
    std::printf("PASS: %zu host-only context behavior checks\n", checks);
}
