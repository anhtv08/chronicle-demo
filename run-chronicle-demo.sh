#!/bin/bash

# Chronicle Demo Runner Script
# This script runs the Chronicle Map/Queue demo with proper JVM arguments

# JVM arguments needed for Chronicle to work with Java 17+
JVM_ARGS="--add-opens java.base/java.lang.reflect=ALL-UNNAMED \
--add-opens java.base/java.nio=ALL-UNNAMED \
--add-opens java.base/sun.nio.ch=ALL-UNNAMED \
--add-opens java.base/java.lang=ALL-UNNAMED \
--add-opens java.base/java.util=ALL-UNNAMED \
--add-exports jdk.compiler/com.sun.tools.javac.file=ALL-UNNAMED \
--add-exports jdk.compiler/com.sun.tools.javac.api=ALL-UNNAMED"

# Check if jar exists
if [ ! -f "target/chronicle-demo-1.0.0.jar" ]; then
    echo "Building the application..."
    mvn clean package -DskipTests
fi

# Run the demo
echo "Running Chronicle Demo..."
echo "========================"

if [ $# -eq 0 ]; then
    echo "Usage: $0 [demo-type]"
    echo "Available demo types:"
    echo "  all        - Run all demonstrations (default)"
    echo "  map        - Chronicle Map demonstrations"
    echo "  queue      - Chronicle Queue demonstrations"
    echo "  benchmark  - Performance benchmarks"
    echo ""
    echo "Running all demos..."
    java $JVM_ARGS -jar target/chronicle-demo-1.0.0.jar all
else
    java $JVM_ARGS -jar target/chronicle-demo-1.0.0.jar $1
fi