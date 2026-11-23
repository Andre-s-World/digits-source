// Publish the existing control protocol counters through I/O Registry properties.
#include "EarlyInitRuntime.hpp"

using namespace DigitsEarlyInit;

void XeneonEarlyInitControl::publishStatus()
{
    setProperty("DriverBundleIdentifier", "local.digits.driver");
    setProperty("DriverVersion", "0.2.4");
    setProperty("RequestStrategy", "native-sync-string-expansion");
    setProperty("State", driverRuntime.state ? driverRuntime.state : "unknown");
    setProperty("Armed", requestsEnabled());
    setProperty("HookInstalled", driverRuntime.hookInstalled);
    setProperty("ModulePinnedForBoot", driverRuntime.pinned);
    setProperty("TargetLocationID", static_cast<uint64_t>(kTargetRoute), 32);
    setProperty("TargetCreations", __atomic_load_n(&driverRuntime.targetCreations, __ATOMIC_RELAXED), 64);
    setProperty("SelectedDevices", __atomic_load_n(&driverRuntime.selectedDevices, __ATOMIC_RELAXED), 64);
    setProperty("AllocationFailures", __atomic_load_n(&driverRuntime.allocationFailures, __ATOMIC_RELAXED), 64);
    setProperty("AutomaticStartupEnabled", true);
    setProperty("StartupLoadTrigger", "IOResources/IOKit");
    setProperty("StartupObserverInstalled", driverRuntime.startupObserver != nullptr);
    setProperty("AutomaticArmAttempts", driverRuntime.automaticArmAttempts, 64);
    setProperty("AutomaticArmResult", static_cast<uint64_t>(driverRuntime.automaticArmResult), 32);
    setProperty("StartupControllerCount", driverRuntime.startupControllerCount, 64);
    setProperty("StartupTargetAlreadyPresentCount", driverRuntime.startupTargetPresentCount, 64);
    setProperty("BootOrderingProven", false);
    setProperty("ModuleStartTicks", driverRuntime.moduleStartTicks, 64);
    setProperty("AutomaticArmTicks", driverRuntime.automaticArmTicks, 64);
    setProperty("HookPublicationTicks", __atomic_load_n(&driverRuntime.hookPublicationTicks, __ATOMIC_ACQUIRE), 64);
    setProperty("FirstTargetFactoryTicks", __atomic_load_n(&driverRuntime.firstTargetFactoryTicks, __ATOMIC_RELAXED), 64);
    setProperty("FirstQualifiedStringTicks", __atomic_load_n(&driverRuntime.firstQualifiedStringTicks, __ATOMIC_RELAXED), 64);
    setProperty("QualifiedStringRequests", __atomic_load_n(&driverRuntime.qualifiedStringRequests, __ATOMIC_RELAXED), 64);
    setProperty("PinnedKernelVersion", XeneonPinnedController::Data::kKernelVersion);
    setProperty("PinnedCollectionSHA256", XeneonPinnedController::Data::kImageSHA256);
    if (driverRuntime.controller)
        setProperty("ControllerRegistryID", driverRuntime.controller->getRegistryEntryID(), 64);
}
