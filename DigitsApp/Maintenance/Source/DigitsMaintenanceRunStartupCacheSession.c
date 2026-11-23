#include "DigitsMaintenanceRunStartupCacheSession.h"
#include <errno.h>
#include <pwd.h>
#include <stdio.h>
#include <string.h>
#include <sys/param.h>
#include <sys/stat.h>
#include <sys/wait.h>
#include <unistd.h>

int DigitsMaintenanceRunStartupCacheSession(void) {
    struct stat consoleStatus;
    if (geteuid() != 0 || stat("/dev/console", &consoleStatus) != 0 || consoleStatus.st_uid == 0) {
        fputs("Startup-cache authorization requires the privileged helper and a signed-in desktop.\n", stderr);
        return 1;
    }
    struct passwd *account = getpwuid(consoleStatus.st_uid);
    if (!account || !account->pw_name || !account->pw_name[0] ||
        strcmp(account->pw_name, "root") == 0 || strcmp(account->pw_name, "loginwindow") == 0 ||
        strcmp(account->pw_name, "_mbsetupuser") == 0 || strcmp(account->pw_name, "nobody") == 0 ||
        strlen(account->pw_name) > MAXLOGNAME) {
        fputs("No valid signed-in account was found; no cache request was sent.\n", stderr);
        return 1;
    }
    char consoleName[MAXLOGNAME + 1];
    strlcpy(consoleName, account->pw_name, sizeof(consoleName));
    fprintf(stderr, "Requesting macOS startup-cache authorization for %s (uid %u).\n",
        consoleName, (unsigned int)consoleStatus.st_uid);
    fflush(stderr);

    // This entry point runs before Foundation starts. fork guarantees the child
    // is not already a process-group leader, so setsid can isolate its login
    // name. Never alter the GUI or privileged parent's shared login session.
    pid_t child = fork();
    if (child < 0) {
        perror("Could not create the startup-cache child");
        return 1;
    }
    if (child == 0) {
        if (setsid() < 0 || setlogin(consoleName) != 0) {
            static const char message[] = "Could not create the account-specific cache session; no cache request was sent.\n";
            write(STDERR_FILENO, message, sizeof(message) - 1);
            _exit(1);
        }
        const char *loginName = getlogin();
        if (geteuid() != 0 || getsid(0) != getpid() || !loginName || strcmp(loginName, consoleName) != 0) {
            static const char message[] = "Startup-cache session verification failed; no cache request was sent.\n";
            write(STDERR_FILENO, message, sizeof(message) - 1);
            _exit(1);
        }
        // kmutil needs root, but selects its LAContext account using getlogin.
        // Keep root privileges and the GUI bootstrap inherited from asuser;
        // the OS still displays and verifies the normal account-password prompt.
        char *const arguments[] = {"/usr/bin/kmutil", "rebuild", NULL};
        execv(arguments[0], arguments);
        static const char message[] = "Could not launch kmutil; the startup cache was not rebuilt.\n";
        write(STDERR_FILENO, message, sizeof(message) - 1);
        _exit(1);
    }
    int status = 0;
    pid_t waited;
    do {
        waited = waitpid(child, &status, 0);
    } while (waited < 0 && errno == EINTR);
    if (waited < 0) {
        perror("Could not read the startup-cache result");
        return 1;
    }
    if (WIFEXITED(status))
        return WEXITSTATUS(status);
    return WIFSIGNALED(status) ? 128 + WTERMSIG(status) : 1;
}
