package com.demo;

import com.demo.benchmark.PerformanceBenchmark;
import com.demo.map.ChronicleMapDemo;
import com.demo.queue.ChronicleQueueDemo;
import lombok.extern.slf4j.Slf4j;

/**
 * Main demo class for Chronicle Map/Queue demonstrations
 */
@Slf4j
public class ChronicleDemo {
    
    public static void main(String[] args) {
        log.info("Chronicle Map/Queue Learning Demo");
        log.info("================================");
        log.info("Welcome to the comprehensive Chronicle Map and Queue demonstration!");
        log.info("");
        
        if (args.length == 0) {
            log.info("Usage: java -jar chronicle-demo.jar [demo-type]");
            log.info("Available demo types:");
            log.info("  map        - Chronicle Map demonstrations");
            log.info("  queue      - Chronicle Queue demonstrations"); 
            log.info("  benchmark  - Performance benchmarks vs standard Java collections");
            log.info("  all        - Run all demonstrations (default)");
            log.info("");
            
            // Run all demos by default
            runAllDemos();
        } else {
            String demoType = args[0].toLowerCase();
            switch (demoType) {
                case "map":
                    ChronicleMapDemo.main(new String[]{});
                    break;
                case "queue":
                    ChronicleQueueDemo.main(new String[]{});
                    break;
                case "benchmark":
                    PerformanceBenchmark.main(new String[]{});
                    break;
                case "all":
                default:
                    runAllDemos();
                    break;
            }
        }
        
        log.info("");
        log.info("Demo completed! Check the 'chronicle-demo-data' directory for generated files.");
    }
    
    private static void runAllDemos() {
        try {
            log.info("Running all Chronicle demonstrations...");
            log.info("");
            
            // Run Chronicle Map demo
            log.info("🗺️  Starting Chronicle Map Demo...");
            ChronicleMapDemo.main(new String[]{});
            
            Thread.sleep(1000); // Small pause between demos
            
            // Run Chronicle Queue demo
            log.info("");
            log.info("📨 Starting Chronicle Queue Demo...");
            ChronicleQueueDemo.main(new String[]{});
            
            Thread.sleep(1000);
            
            // Run performance benchmark
            log.info("");
            log.info("⚡ Starting Performance Benchmark...");
            PerformanceBenchmark.main(new String[]{});
            
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            log.error("Demo interrupted", e);
        }
    }
}