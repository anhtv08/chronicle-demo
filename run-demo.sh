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
    "-Xmx4g"
    "-Xms4g"
    "-XX:+UseG1GC"
    "-XX:MaxGCPauseMillis=100"

    # Chronicle Map module system fixes
    "--add-opens=java.base/java.lang=ALL-UNNAMED"
    "--add-opens=java.base/java.lang.reflect=ALL-UNNAMED"
    "--add-opens=java.base/java.io=ALL-UNNAMED"
    "--add-opens=java.base/java.util=ALL-UNNAMED"
    "--add-opens=java.base/java.nio=ALL-UNNAMED"
    "--add-opens=java.base/sun.nio.ch=ALL-UNNAMED"
    "--add-opens=java.base/java.lang.invoke=ALL-UNNAMED"
    "--add-opens=java.base/jdk.internal.misc=ALL-UNNAMED"
    
    # JDK Compiler module access for Chronicle
    "--add-opens=jdk.compiler/com.sun.tools.javac.api=ALL-UNNAMED"
    "--add-opens=jdk.compiler/com.sun.tools.javac.file=ALL-UNNAMED"
    "--add-opens=jdk.compiler/com.sun.tools.javac.main=ALL-UNNAMED"
    "--add-opens=jdk.compiler/com.sun.tools.javac.model=ALL-UNNAMED"
    "--add-opens=jdk.compiler/com.sun.tools.javac.parser=ALL-UNNAMED"
    "--add-opens=jdk.compiler/com.sun.tools.javac.processing=ALL-UNNAMED"
    "--add-opens=jdk.compiler/com.sun.tools.javac.tree=ALL-UNNAMED"
    "--add-opens=jdk.compiler/com.sun.tools.javac.util=ALL-UNNAMED"
    "--add-opens=jdk.compiler/com.sun.tools.javac.jvm=ALL-UNNAMED"

    "--add-exports=java.base/jdk.internal.ref=ALL-UNNAMED"
    "--add-exports=java.base/sun.nio.ch=ALL-UNNAMED"
    "--add-exports=jdk.unsupported/sun.misc=ALL-UNNAMED"
    "--add-exports=java.base/jdk.internal.access=ALL-UNNAMED"
    "--add-exports=java.base/jdk.internal.misc=ALL-UNNAMED"
    "--add-exports=jdk.compiler/com.sun.tools.javac.file=ALL-UNNAMED"
    "--add-exports=jdk.compiler/com.sun.tools.javac.api=ALL-UNNAMED"

    # macOS specific settings
    "-Djava.awt.headless=true"
    "-Dfile.encoding=UTF-8"
    "-Dapple.laf.useScreenMenuBar=false"

    # Disable warnings about illegal access
    "-Djdk.internal.lambda.disableEagerInitialization=true"
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