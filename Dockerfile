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
FROM amazoncorretto:17

# Install required packages for Chronicle (native libraries)
RUN yum update -y && yum install -y \
    glibc-devel \
    && yum clean all

# Create app directory and user
RUN yum install -y shadow-utils && \
    groupadd -g 1001 appgroup && \
    useradd -u 1001 -g appgroup -s /bin/bash appuser

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

# Install netcat for health checks
USER root
RUN yum install -y nc && yum clean all
USER appuser

# Create a simple health check script
RUN echo '#!/bin/bash' > /app/health-server.sh && \
    echo 'while true; do' >> /app/health-server.sh && \
    echo '  echo -e "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: 44\r\n\r\n{\"status\":\"UP\",\"service\":\"chronicle-demo\"}" | nc -l -p 8080 -q 1' >> /app/health-server.sh && \
    echo 'done' >> /app/health-server.sh && \
    chmod +x /app/health-server.sh

# Create startup script
RUN echo '#!/bin/bash' > /app/start.sh && \
    echo 'echo "Starting Chronicle Demo..."' >> /app/start.sh && \
    echo '# Start health check server in background' >> /app/start.sh && \
    echo '/app/health-server.sh &' >> /app/start.sh && \
    echo 'HEALTH_PID=$!' >> /app/start.sh && \
    echo 'echo "Health check server started on port 8080 (PID: $HEALTH_PID)"' >> /app/start.sh && \
    echo '# Run the main application' >> /app/start.sh && \
    echo 'echo "Starting Chronicle application..."' >> /app/start.sh && \
    echo 'java $JAVA_OPTS -jar app.jar all' >> /app/start.sh && \
    echo 'APP_EXIT_CODE=$?' >> /app/start.sh && \
    echo '# Clean up health server on exit' >> /app/start.sh && \
    echo 'kill $HEALTH_PID 2>/dev/null || true' >> /app/start.sh && \
    echo 'exit $APP_EXIT_CODE' >> /app/start.sh && \
    chmod +x /app/start.sh

# Health check endpoint
EXPOSE 8080

# Default command
CMD ["/app/start.sh"]