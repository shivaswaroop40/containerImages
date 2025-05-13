# syntax=docker/dockerfile:1.4

# Build stage
FROM cgr.dev/chainguard/busybox AS builder
WORKDIR /app
COPY . .

# Final stage
FROM cgr.dev/chainguard/busybox:latest

# Add metadata labels
LABEL org.opencontainers.image.source="https://github.com/shivaswaroop40/containerImages"
LABEL org.opencontainers.image.description="Secure container image with supply chain security"
LABEL org.opencontainers.image.licenses="MIT"

# Create non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Set working directory
WORKDIR /app

# Copy only necessary files from builder
COPY --from=builder /app .

# Set proper permissions
RUN chown -R appuser:appgroup /app

# Switch to non-root user
USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/health || exit 1

# Set environment variables
ENV NODE_ENV=dev

# Expose port if needed
EXPOSE 8080

# Use JSON array format for CMD to handle signals properly
CMD ["/bin/sh", "-c", "echo 'Hello, World!' && while true; do sleep 3600; done"]
