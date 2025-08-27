---
layout: post
title: Java remote JMX monitoring
---

This program monitors remote JMX.

```java
public interface RemoteJMX extends AutoCloseable {
    void init();
    void logStats();

    @NotNull
    static RemoteJMX connectToRemote() {
        final List<VirtualMachineDescriptor> list = VirtualMachine.list();
        var vmds = list.stream()
                .filter(it -> it.displayName().equals("com.example.Main")) // or some other way to find the VM you're interested in.
                .collect(Collectors.toList());
        return RemoteJVM.connect(vmds.get(0));
    }
}

public static class GCSampler {
    private volatile long cumulativeGCTimeSpent = -1;
    private volatile long lastGCCollectionTimeAt = -1;
    @NotNull
    private final List<GarbageCollectorMXBean> mxBeans;

    public GCSampler(@NotNull List<GarbageCollectorMXBean> mxBeans) {
        this.mxBeans = mxBeans;
    }

    /**
     * GC load, 0.0-1.0. 0 means no GC load, 1 means GC used 1 CPU cure fully, 2 means GC used 2 CPU cores fully since the last time sample was taken.
     * @return 0.0 or higher; 0 if not available.
     */
    public double getLoad() {
        double result = 0;
        long cumulativeTimeSpent = 0;
        for (GarbageCollectorMXBean mxBean : mxBeans) {
            cumulativeTimeSpent += mxBean.getCollectionTime();
        }
        final long currentTimeMillis = System.currentTimeMillis();
        if (lastGCCollectionTimeAt < 0) {
            cumulativeGCTimeSpent = cumulativeTimeSpent;
        } else {
            long timeElapsedBetweenTwoMeasurements = currentTimeMillis - lastGCCollectionTimeAt;
            if (timeElapsedBetweenTwoMeasurements > 0) {
                long lastGCTimeSpent = cumulativeTimeSpent - cumulativeGCTimeSpent;
                result = ((double) lastGCTimeSpent) / timeElapsedBetweenTwoMeasurements;
                cumulativeGCTimeSpent = cumulativeTimeSpent;
            }
        }
        lastGCCollectionTimeAt = currentTimeMillis;
        return result;
    }
}

public static class RemoteJVM implements RemoteJMX {
    @NotNull
    private final JMXConnector connector;
    private volatile OperatingSystemMXBean operatingSystemMXBean;
    private volatile GCSampler gcSampler;
    private int cpuCount = 1;

    public RemoteJVM(@NotNull JMXConnector connector) {
        this.connector = connector;
    }

    @NotNull
    private <T extends PlatformManagedObject> T getMXBean(@NotNull String objectName, @NotNull Class<T> type) {
        try {
            final MBeanServerConnection mbc = connector.getMBeanServerConnection();
            var proxy = MBeanServerInvocationHandler.newProxyInstance(mbc, new ObjectName(objectName), type, false);
            return type.cast(proxy);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }

    public void init() {
        try {
            List<GarbageCollectorMXBean> gcMXBeans = new ArrayList<>();
            Set<ObjectName> gcnames = new HashSet<>(connector.getMBeanServerConnection().queryNames(null, null));
            gcnames.removeIf(it -> !it.getCanonicalName().contains("type=GarbageCollector"));
            for (ObjectName gcname : gcnames) {
                GarbageCollectorMXBean mxbean = getMXBean(gcname.getCanonicalName(), GarbageCollectorMXBean.class);
                if (mxbean.isValid()) {
                    gcMXBeans.add(mxbean);
                }
            }
            gcSampler = new GCSampler(gcMXBeans);
            operatingSystemMXBean = getMXBean("java.lang:type=OperatingSystem", OperatingSystemMXBean.class);
            cpuCount = operatingSystemMXBean.getAvailableProcessors();
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }

    @NotNull
    public static RemoteJVM connect(@NotNull VirtualMachineDescriptor vmd) throws Exception {
        var vm = VirtualMachine.attach(vmd);
        final String address = vm.getAgentProperties().getProperty("com.sun.management.jmxremote.localConnectorAddress");
        final JMXServiceURL url = new JMXServiceURL(address);
        JMXConnector connector = JMXConnectorFactory.connect(url);
        return new RemoteJVM(connector);
    }

    public void logStats() {
        try {
            var o = connector.getMBeanServerConnection().getAttribute(new ObjectName("java.lang:type=Memory"), "HeapMemoryUsage");
            CompositeData cd = (CompositeData) o;
            // committed represents the amount of memory (in bytes) that is guaranteed to be available for use by the JVM. This memory is reserved by the operating system for the JVM process and is always greater than or equal to used. The JVM can request additional memory from the OS if committed is insufficient, and it can also release memory back to the OS, potentially making committed less than init.
            final long committedMb = ((Long) cd.get("committed")) / 1000 / 1000;
            // init represents the initial amount of memory (in bytes) that the JVM requests from the operating system for memory management during startup. This value is typically close to the -Xms (initial heap size) setting, though it may be undefined.
            final long initMb = ((Long) cd.get("init")) / 1000 / 1000;
            // max represents the maximum amount of memory (in bytes) that can be used for memory management. This value is typically close to the -Xmx (maximum heap size) setting, though it may be undefined (e.g., -1) if no limit is set. The used and committed values will always be less than or equal to max if max is defined. A memory allocation can fail if the JVM attempts to increase used beyond committed, even if used is still less than or equal to max, particularly when the system is low on virtual memory.
            final long maxMb = ((Long) cd.get("max")) / 1000 / 1000;
            // used represents the amount of memory (in bytes) that is currently being used by the JVM. This includes memory occupied by objects, including those that are no longer reachable but not yet garbage collected.
            final long usedMb = ((Long) cd.get("used")) / 1000 / 1000;
            log.info("ELSA/JMX memory stats: used " + usedMb + "mb committed " + committedMb + "mb of " + maxMb + "mb");
            final double load = operatingSystemMXBean.getProcessCpuLoad();
            log.info("ELSA/JMX CPU stats: avg CPU usage since last measurement: " + (int) (load * 100 * cpuCount) + "%; avg GC usage: " + (int)(gcSampler.getLoad() * 100) + "%; 100%=1 CPU core fully used");
        } catch (Exception ex) {
            log.error("ELSA/JMX: Failed to obtain memory stats", ex);
        }
    }

    @Override
    public void close() throws Exception {
        connector.close();
    }
}
```