# Multi-stage build for Chronicle Demo
FROM maven:3.9.4-eclipse-temurin-17 AS builder

# Set working directory
WORKDIR /app

# Copy pom.xml first for better layer caching
COPY pom.xml .

# Download dependencies
RUN mvn dependency:go-offline -B

# Copy source code
COPY src ./src

# Build the application
RUN mvn clean package -DskipTests

# Runtime stage
FROM eclipse-temurin:17-jre-alpine

# Install required packages for Chronicle (native libraries)
RUN apk add --no-cache \
    gcompat \
    libc6-compat

# Create app directory and user
RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup

WORKDIR /app

# Copy the fat jar from builder stage
COPY --from=builder /app/target/chronicle-demo-1.0.0.jar app.jar

# Create data directory for Chronicle files
RUN mkdir -p /app/chronicle-demo-data && \
    chown -R appuser:appgroup /app

# Switch to non-root user
USER appuser

# Expose any ports if needed (none required for this demo)
# EXPOSE 8080

# Set JVM options for Chronicle performance
ENV JAVA_OPTS="-Xmx2g -Xms1g -XX:+UseG1GC -XX:+UnlockExperimentalVMOptions -XX:+UseTransparentHugePages --add-opens java.base/java.lang.reflect=ALL-UNNAMED --add-opens java.base/java.nio=ALL-UNNAMED --add-opens java.base/sun.nio.ch=ALL-UNNAMED --add-opens java.base/java.lang=ALL-UNNAMED --add-opens java.base/java.util=ALL-UNNAMED --add-exports jdk.compiler/com.sun.tools.javac.file=ALL-UNNAMED --add-exports jdk.compiler/com.sun.tools.javac.api=ALL-UNNAMED"

# Default command runs all demos
CMD ["sh", "-c", "java $JAVA_OPTS -jar app.jar all"]