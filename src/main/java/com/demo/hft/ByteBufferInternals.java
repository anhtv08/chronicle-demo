package com.demo.hft;

import sun.misc.Unsafe;

import java.lang.reflect.Field;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;

public class ByteBufferInternals {

    private static final Unsafe UNSAFE = getUnsafe();

    // ==== BYTEBUFFER INTERNAL STRUCTURE ====

    public static class ByteBufferAnalysis {

        public static void analyzeInternalStructure() {
            System.out.println("=== ByteBuffer Internal Structure Analysis ===\n");

            // Create different types of ByteBuffers
            ByteBuffer heapBuffer = ByteBuffer.allocate(1024);
            ByteBuffer directBuffer = ByteBuffer.allocateDirect(1024);

            System.out.println("1. HEAP BYTEBUFFER:");
            analyzeBuffer(heapBuffer);

            System.out.println("\n2. DIRECT BYTEBUFFER:");
            analyzeBuffer(directBuffer);

            System.out.println("\n3. INTERNAL FIELDS:");
            printInternalFields(heapBuffer, "Heap Buffer");
            printInternalFields(directBuffer, "Direct Buffer");
        }

        private static void analyzeBuffer(ByteBuffer buffer) {
            System.out.println("Class: " + buffer.getClass().getName());
            System.out.println("isDirect: " + buffer.isDirect());
            System.out.println("hasArray: " + buffer.hasArray());
            System.out.println("isReadOnly: " + buffer.isReadOnly());
            System.out.println("position: " + buffer.position());
            System.out.println("limit: " + buffer.limit());
            System.out.println("capacity: " + buffer.capacity());
            System.out.println("remaining: " + buffer.remaining());
            System.out.println("order: " + buffer.order());
        }

        private static void printInternalFields(ByteBuffer buffer, String type) {
            System.out.println("\n" + type + " Internal Fields:");

            try {
                // Common fields from Buffer class
                Field positionField = buffer.getClass().getSuperclass().getDeclaredField("position");
                Field limitField = buffer.getClass().getSuperclass().getDeclaredField("limit");
                Field capacityField = buffer.getClass().getSuperclass().getDeclaredField("capacity");

                positionField.setAccessible(true);
                limitField.setAccessible(true);
                capacityField.setAccessible(true);

                System.out.println("  position: " + positionField.get(buffer));
                System.out.println("  limit: " + limitField.get(buffer));
                System.out.println("  capacity: " + capacityField.get(buffer));

                if (buffer.isDirect()) {
                    // DirectByteBuffer specific fields
                    Field addressField = buffer.getClass().getDeclaredField("address");
                    addressField.setAccessible(true);
                    long address = addressField.getLong(buffer);
                    System.out.println("  address: 0x" + Long.toHexString(address));

                    Field cleanerField = buffer.getClass().getDeclaredField("cleaner");
                    cleanerField.setAccessible(true);
                    Object cleaner = cleanerField.get(buffer);
                    System.out.println("  cleaner: " + cleaner);

                } else {
                    // HeapByteBuffer specific fields
                    Field hbField = buffer.getClass().getDeclaredField("hb");
                    hbField.setAccessible(true);
                    byte[] hb = (byte[]) hbField.get(buffer);
                    System.out.println("  hb (backing array): " + hb.length + " bytes");

                    Field offsetField = buffer.getClass().getDeclaredField("offset");
                    offsetField.setAccessible(true);
                    int offset = offsetField.getInt(buffer);
                    System.out.println("  offset: " + offset);
                }

            } catch (Exception e) {
                System.out.println("  Error accessing fields: " + e.getMessage());
            }
        }
    }

    // ==== POSITION, LIMIT, CAPACITY MECHANICS ====

    public static class BufferMechanics {

        public static void demonstratePositionLimitCapacity() {
            System.out.println("\n=== ByteBuffer Position/Limit/Capacity Mechanics ===\n");

            ByteBuffer buffer = ByteBuffer.allocate(10);
            printBufferState(buffer, "Initial state");

            // Write some data
            buffer.put((byte) 1);
            buffer.put((byte) 2);
            buffer.put((byte) 3);
            printBufferState(buffer, "After writing 3 bytes");

            // Flip for reading
            buffer.flip();
            printBufferState(buffer, "After flip()");

            // Read some data
            byte b1 = buffer.get();
            byte b2 = buffer.get();
            printBufferState(buffer, "After reading 2 bytes");

            // Compact
            buffer.compact();
            printBufferState(buffer, "After compact()");

            // Clear
            buffer.clear();
            printBufferState(buffer, "After clear()");
        }

        private static void printBufferState(ByteBuffer buffer, String description) {
            System.out.printf("%-25s: pos=%d, lim=%d, cap=%d, rem=%d\n",
                    description, buffer.position(), buffer.limit(),
                    buffer.capacity(), buffer.remaining());

            // Visual representation
            System.out.print("                         : [");
            for (int i = 0; i < buffer.capacity(); i++) {
                if (i == buffer.position()) System.out.print("P");
                else if (i == buffer.limit()) System.out.print("L");
                else if (i < buffer.position()) System.out.print("*");
                else if (i >= buffer.limit()) System.out.print("-");
                else System.out.print(" ");
            }
            System.out.println("]");
            System.out.println();
        }
    }

    // ==== PERFORMANCE COMPARISON ====

    public static class PerformanceAnalysis {

        public static void performanceComparison() {
            System.out.println("\n=== ByteBuffer Performance Analysis ===\n");

            int iterations = 10_000_000;
            int bufferSize = 1024;

            // Test different access methods
            testArrayAccess(iterations);
            testHeapBufferAccess(iterations, bufferSize);
            testDirectBufferAccess(iterations, bufferSize);
            testUnsafeAccess(iterations, bufferSize);
            testOptimizedDirectBuffer(iterations, bufferSize);
        }

        private static void testArrayAccess(int iterations) {
            byte[] array = new byte[1024];

            long start = System.nanoTime();
            for (int i = 0; i < iterations; i++) {
                array[0] = (byte) i;
                array[4] = (byte) (i >> 8);
                array[8] = (byte) (i >> 16);

                byte b1 = array[0];
                byte b2 = array[4];
                byte b3 = array[8];
            }
            long time = System.nanoTime() - start;

            System.out.printf("Array Access:           %8.2f ns/op\n",
                    (double) time / iterations);
        }

        private static void testHeapBufferAccess(int iterations, int size) {
            ByteBuffer buffer = ByteBuffer.allocate(size);

            long start = System.nanoTime();
            for (int i = 0; i < iterations; i++) {
                buffer.position(0);
                buffer.put((byte) i);
                buffer.putInt(i);
                buffer.putLong(i);

                buffer.position(0);
                byte b = buffer.get();
                int intVal = buffer.getInt();
                long longVal = buffer.getLong();
            }
            long time = System.nanoTime() - start;

            System.out.printf("Heap ByteBuffer:        %8.2f ns/op\n",
                    (double) time / iterations);
        }

        private static void testDirectBufferAccess(int iterations, int size) {
            ByteBuffer buffer = ByteBuffer.allocateDirect(size);

            long start = System.nanoTime();
            for (int i = 0; i < iterations; i++) {
                buffer.position(0);
                buffer.put((byte) i);
                buffer.putInt(i);
                buffer.putLong(i);

                buffer.position(0);
                byte b = buffer.get();
                int intVal = buffer.getInt();
                long longVal = buffer.getLong();
            }
            long time = System.nanoTime() - start;

            System.out.printf("Direct ByteBuffer:      %8.2f ns/op\n",
                    (double) time / iterations);
        }

        private static void testUnsafeAccess(int iterations, int size) {
            long address = UNSAFE.allocateMemory(size);

            long start = System.nanoTime();
            for (int i = 0; i < iterations; i++) {
                UNSAFE.putByte(address, (byte) i);
                UNSAFE.putInt(address + 1, i);
                UNSAFE.putLong(address + 5, i);

                byte b = UNSAFE.getByte(address);
                int intVal = UNSAFE.getInt(address + 1);
                long longVal = UNSAFE.getLong(address + 5);
            }
            long time = System.nanoTime() - start;

            UNSAFE.freeMemory(address);

            System.out.printf("Unsafe Access:          %8.2f ns/op\n",
                    (double) time / iterations);
        }

        private static void testOptimizedDirectBuffer(int iterations, int size) {
            ByteBuffer buffer = ByteBuffer.allocateDirect(size);
            buffer.order(ByteOrder.nativeOrder()); // Important optimization!

            long start = System.nanoTime();
            for (int i = 0; i < iterations; i++) {
                // Absolute positioning - no position() calls
                buffer.put(0, (byte) i);
                buffer.putInt(1, i);
                buffer.putLong(5, i);

                byte b = buffer.get(0);
                int intVal = buffer.getInt(1);
                long longVal = buffer.getLong(5);
            }
            long time = System.nanoTime() - start;

            System.out.printf("Optimized DirectBuffer: %8.2f ns/op\n",
                    (double) time / iterations);
        }
    }

    // ==== BYTEBUFFER OPTIMIZATION TECHNIQUES ====

    public static class OptimizationTechniques {

        public static void demonstrateOptimizations() {
            System.out.println("\n=== ByteBuffer Optimization Techniques ===\n");

            // 1. Native byte order
            demonstrateByteOrder();

            // 2. Bulk operations
            demonstrateBulkOperations();

            // 3. View buffers
            demonstrateViewBuffers();

            // 4. Slice and duplicate
            demonstrateSliceAndDuplicate();
        }

        private static void demonstrateByteOrder() {
            System.out.println("1. BYTE ORDER OPTIMIZATION:");

            ByteBuffer buffer = ByteBuffer.allocateDirect(1024);

            // Default order (usually BIG_ENDIAN)
            System.out.println("Default order: " + buffer.order());
            System.out.println("Native order: " + ByteOrder.nativeOrder());

            // Set to native order for better performance
            buffer.order(ByteOrder.nativeOrder());
            System.out.println("Buffer order after optimization: " + buffer.order());

            // Performance difference can be significant on some platforms
            System.out.println("💡 Always use ByteOrder.nativeOrder() for best performance\n");
        }

        private static void demonstrateBulkOperations() {
            System.out.println("2. BULK OPERATIONS:");

            ByteBuffer src = ByteBuffer.allocateDirect(1024);
            ByteBuffer dst = ByteBuffer.allocateDirect(1024);
            byte[] array = new byte[1024];

            // Fill source buffer
            for (int i = 0; i < 1024; i++) {
                src.put((byte) i);
            }
            src.flip();

            // Bulk copy - much faster than individual puts/gets
            long start = System.nanoTime();
            dst.put(src);
            long bulkTime = System.nanoTime() - start;

            src.rewind();
            dst.clear();

            // Individual copies - slower
            start = System.nanoTime();
            while (src.hasRemaining()) {
                dst.put(src.get());
            }
            long individualTime = System.nanoTime() - start;

            System.out.printf("Bulk copy:       %d ns\n", bulkTime);
            System.out.printf("Individual copy: %d ns\n", individualTime);
            System.out.printf("Bulk is %.1fx faster\n\n",
                    (double) individualTime / bulkTime);
        }

        private static void demonstrateViewBuffers() {
            System.out.println("3. VIEW BUFFERS:");

            ByteBuffer buffer = ByteBuffer.allocateDirect(1024);
            buffer.order(ByteOrder.nativeOrder());

            // Create typed views - no data copying!
            var intBuffer = buffer.asIntBuffer();
            var longBuffer = buffer.asLongBuffer();
            var doubleBuffer = buffer.asDoubleBuffer();

            System.out.println("Original buffer capacity: " + buffer.capacity());
            System.out.println("Int view capacity: " + intBuffer.capacity());
            System.out.println("Long view capacity: " + longBuffer.capacity());
            System.out.println("Double view capacity: " + doubleBuffer.capacity());

            // Write through int view
            intBuffer.put(0, 0x12345678);

            // Read through byte view - same memory!
            System.out.printf("Written as int: 0x%08X\n", intBuffer.get(0));
            System.out.printf("Read as bytes: 0x%02X%02X%02X%02X\n",
                    buffer.get(0), buffer.get(1), buffer.get(2), buffer.get(3));

            System.out.println("💡 View buffers provide zero-copy type conversion\n");
        }

        private static void demonstrateSliceAndDuplicate() {
            System.out.println("4. SLICE AND DUPLICATE:");

            ByteBuffer original = ByteBuffer.allocateDirect(100);

            // Put some data
            for (int i = 0; i < 20; i++) {
                original.put((byte) i);
            }

            // Create slice - shares data but independent position/limit
            original.position(10).limit(15);
            ByteBuffer slice = original.slice();

            System.out.println("Original: pos=" + original.position() +
                    ", lim=" + original.limit() +
                    ", cap=" + original.capacity());
            System.out.println("Slice: pos=" + slice.position() +
                    ", lim=" + slice.limit() +
                    ", cap=" + slice.capacity());

            // Duplicate - shares data and position/limit
            ByteBuffer duplicate = original.duplicate();
            System.out.println("Duplicate: pos=" + duplicate.position() +
                    ", lim=" + duplicate.limit() +
                    ", cap=" + duplicate.capacity());

            System.out.println("💡 Use slice() for independent cursors, duplicate() for shared cursors\n");
        }
    }

    // ==== MEMORY MANAGEMENT ====

    public static class MemoryManagement {

        public static void demonstrateMemoryManagement() {
            System.out.println("\n=== ByteBuffer Memory Management ===\n");

            // Heap buffer - managed by GC
            ByteBuffer heapBuffer = ByteBuffer.allocate(1024);
            System.out.println("Heap buffer created - managed by GC");

            // Direct buffer - off-heap memory
            ByteBuffer directBuffer = ByteBuffer.allocateDirect(1024);
            System.out.println("Direct buffer created - off-heap memory");

            // Check memory usage
            Runtime runtime = Runtime.getRuntime();
            long usedMemory = runtime.totalMemory() - runtime.freeMemory();
            System.out.println("Used heap memory: " + usedMemory / 1024 + " KB");

            // Direct buffer cleanup
            System.out.println("\n💡 Direct buffers are cleaned up by:");
            System.out.println("   1. Cleaner thread (automatic)");
            System.out.println("   2. System.gc() (forces cleanup)");
            System.out.println("   3. Going out of scope (eventually)");

            // Force cleanup (not recommended in production)
            directBuffer = null;
            System.gc();
            System.out.println("   Called System.gc() to demonstrate cleanup");
        }
    }

    // ==== TRADING SYSTEM EXAMPLE ====

    public static class TradingSystemExample {

        // Market data message format
        private static final int SYMBOL_OFFSET = 0;
        private static final int SYMBOL_LENGTH = 8;
        private static final int PRICE_OFFSET = 8;
        private static final int QUANTITY_OFFSET = 16;
        private static final int TIMESTAMP_OFFSET = 24;
        private static final int MESSAGE_SIZE = 32;

        public static void demonstrateTradingUseCase() {
            System.out.println("\n=== Trading System ByteBuffer Usage ===\n");

            // Pre-allocate buffer for message processing
            ByteBuffer messageBuffer = ByteBuffer.allocateDirect(MESSAGE_SIZE);
            messageBuffer.order(ByteOrder.nativeOrder());

            // Simulate parsing market data message
            parseMarketDataMessage(messageBuffer, "AAPL    ", 150.25, 1000, System.nanoTime());

            // Read back the data
            MarketDataMessage msg = readMarketDataMessage(messageBuffer);
            System.out.println("Parsed message: " + msg);

            // Performance test
            int iterations = 1_000_000;
            long start = System.nanoTime();

            for (int i = 0; i < iterations; i++) {
                messageBuffer.clear();
                parseMarketDataMessage(messageBuffer, "MSFT    ", 280.50 + i * 0.01, 1000 + i, System.nanoTime());
                readMarketDataMessage(messageBuffer);
            }

            long time = System.nanoTime() - start;
            System.out.printf("Processed %d messages in %.2f ms\n", iterations, time / 1_000_000.0);
            System.out.printf("Throughput: %.0f messages/second\n", iterations * 1_000_000_000.0 / time);
        }

        private static void parseMarketDataMessage(ByteBuffer buffer, String symbol, double price, int quantity, long timestamp) {
            buffer.clear();

            // Write symbol (8 bytes, padded)
            byte[] symbolBytes = symbol.getBytes();
            buffer.put(symbolBytes, 0, Math.min(symbolBytes.length, SYMBOL_LENGTH));

            // Write price, quantity, timestamp
            buffer.putDouble(PRICE_OFFSET, price);
            buffer.putInt(QUANTITY_OFFSET, quantity);
            buffer.putLong(TIMESTAMP_OFFSET, timestamp);
        }

        private static MarketDataMessage readMarketDataMessage(ByteBuffer buffer) {
            // Read symbol
            byte[] symbolBytes = new byte[SYMBOL_LENGTH];
            buffer.position(SYMBOL_OFFSET);
            buffer.get(symbolBytes);
            String symbol = new String(symbolBytes).trim();

            // Read price, quantity, timestamp using absolute positioning
            double price = buffer.getDouble(PRICE_OFFSET);
            int quantity = buffer.getInt(QUANTITY_OFFSET);
            long timestamp = buffer.getLong(TIMESTAMP_OFFSET);

            return new MarketDataMessage(symbol, price, quantity, timestamp);
        }

        private static class MarketDataMessage {
            final String symbol;
            final double price;
            final int quantity;
            final long timestamp;

            MarketDataMessage(String symbol, double price, int quantity, long timestamp) {
                this.symbol = symbol;
                this.price = price;
                this.quantity = quantity;
                this.timestamp = timestamp;
            }

            @Override
            public String toString() {
                return String.format("%s: $%.2f x %d @ %d", symbol, price, quantity, timestamp);
            }
        }
    }

    private static Unsafe getUnsafe() {
        try {
            Field field = Unsafe.class.getDeclaredField("theUnsafe");
            field.setAccessible(true);
            return (Unsafe) field.get(null);
        } catch (Exception e) {
            throw new RuntimeException("Cannot access Unsafe", e);
        }
    }

    public static void main(String[] args) {
        ByteBufferAnalysis.analyzeInternalStructure();
        BufferMechanics.demonstratePositionLimitCapacity();
        PerformanceAnalysis.performanceComparison();
        OptimizationTechniques.demonstrateOptimizations();
        MemoryManagement.demonstrateMemoryManagement();
        TradingSystemExample.demonstrateTradingUseCase();

        System.out.println("\n=== ByteBuffer Best Practices Summary ===");
        System.out.println("🚀 Use ByteBuffer.allocateDirect() for performance");
        System.out.println("⚡ Set ByteOrder.nativeOrder() for speed");
        System.out.println("📦 Use bulk operations when possible");
        System.out.println("🎯 Use absolute positioning to avoid position() calls");
        System.out.println("🔄 Reuse buffers to avoid allocation overhead");
        System.out.println("👀 Use view buffers for type conversion");
        System.out.println("⚠️  Be careful with direct buffer memory management");
    }
}
