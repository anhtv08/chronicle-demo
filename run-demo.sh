#!/bin/bash

# Chronicle Map/Queue Demo Runner Script
# Optimized for performance testing

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Chronicle Map/Queue Demo Runner${NC}"
echo -e "${BLUE}========================================${NC}"

# Check Java version
JAVA_VERSION=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2 | cut -d'.' -f1)
if [ "$JAVA_VERSION" -lt 17 ]; then
    echo -e "${RED}Error: Java 17 or higher is required. Current version: $JAVA_VERSION${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Java version check passed${NC}"

# Set demo type from command line argument
DEMO_TYPE=${1:-all}

# Performance-optimized JVM arguments
JVM_ARGS=(
    # Memory settings
    "-Xms1g"                          # Initial heap size
    "-Xmx2g"                          # Maximum heap size
    
    # GC tuning for low latency
    "-XX:+UseG1GC"                    # Use G1 garbage collector
    "-XX:MaxGCPauseMillis=10"         # Target max GC pause time
    "-XX:G1HeapRegionSize=16m"        # G1 heap region size
    
    # Performance optimizations
    "-XX:+UnlockExperimentalVMOptions"
    "-XX:+UseLargePages"              # Use large memory pages (if available)
    "-XX:+AlwaysPreTouch"             # Pre-touch memory pages
    "-XX:+OptimizeStringConcat"       # Optimize string concatenation
    
    # Compilation optimizations
    "-XX:+TieredCompilation"          # Enable tiered compilation
    "-XX:CompileThreshold=1000"       # Lower compilation threshold
    
    # System properties for Chronicle
    "-Dchronicle.analytics.disable=true"  # Disable Chronicle analytics
    "-Dfile.encoding=UTF-8"               # Set file encoding
    
    # Server VM
    "-server"                         # Server VM
)

# Check if JAR exists, build if necessary
JAR_FILE="target/chronicle-demo-1.0.0.jar"
if [ ! -f "$JAR_FILE" ]; then
    echo -e "${YELLOW}Building JAR file...${NC}"
    mvn clean package -DskipTests -q
fi

# Create logs directory
mkdir -p logs

# Print configuration
echo -e "${BLUE}Configuration:${NC}"
echo -e "  Demo Type: $DEMO_TYPE"
echo -e "  Heap Size: 1-2GB"
echo -e "  GC: G1 with 10ms max pause"
echo -e "  Large Pages: Enabled (if available)"
echo -e "  Chronicle Analytics: Disabled"

# Build the full command
FULL_COMMAND="java"
for arg in "${JVM_ARGS[@]}"; do
    FULL_COMMAND="$FULL_COMMAND $arg"
done
FULL_COMMAND="$FULL_COMMAND -jar $JAR_FILE $DEMO_TYPE"

echo -e "${BLUE}Starting Chronicle Demo...${NC}"
echo -e "${YELLOW}Command: $FULL_COMMAND${NC}"
echo ""

# Execute the demo
exec $FULL_COMMAND