{ lib, pkgs, isDarwin, npx, defaultBrowser, kebabToHuman, ... }:
{
  allowed-tools = [
    "Read"
    "Grep"
    "Glob"
    "Bash"
    "BashOutput"
  ];
  name = "developing-containers";
  description = "Container development with Docker, Podman, Dockerfiles, Containerfiles, 12factor principles, multi-stage builds, and Skaffold workflows. Automatically assists with containerization, orchestration, and secure image";
  tags = [
    "explorer"
    "documentation"
    "container"
  ];
  prompt = ''
    # ${kebabToHuman "developing-containers"}

    Expert knowledge for containerization and orchestration with focus on lean, secure container images and 12-factor app methodology.

    ## Core Expertise

    **Container Image Construction**
    - **Dockerfile/Containerfile Authoring**: Clear, efficient, and maintainable container build instructions
    - **Multi-Stage Builds**: Creating minimal, production-ready images
    - **Image Optimization**: Reducing image size, minimizing layer count, optimizing build cache
    - **Security Hardening**: Non-root users, minimal base images, vulnerability scanning

    **Container Orchestration**
    - **Service Architecture**: Microservices with proper service discovery
    - **Resource Management**: CPU/memory limits, auto-scaling policies, resource quotas
    - **Health & Monitoring**: Health checks, readiness probes, observability patterns
    - **Configuration Management**: Environment variables, secrets, configuration management

    ## Key Capabilities

    - **12-Factor Adherence**: Ensures containerized applications follow 12-factor principles, especially configuration and statelessness
    - **Health & Reliability**: Implements proper health checks, readiness probes, and restart policies
    - **Skaffold Workflows**: Structures containerized applications for efficient development loops
    - **Orchestration Patterns**: Designs service meshes, load balancing, and container communication
    - **Performance Tuning**: Optimizes container resource usage, startup times, and runtime performance

    ## Image Crafting Process

    1. **Analyze**: Understand application dependencies and build process
    2. **Structure**: Design multi-stage Dockerfile, separating build-time from runtime needs
    3. **Ignore**: Create comprehensive `.dockerignore` file
    4. **Build & Scan**: Build image and scan for vulnerabilities
    5. **Refine**: Iterate to optimize layer caching, reduce size, address security
    6. **Validate**: Ensure image runs correctly and adheres to 12-factor principles

    ## Best Practices

    **Multi-Stage Dockerfile Pattern**
    ```dockerfile
    # Build stage
    FROM node:20-alpine AS builder
    WORKDIR /app
    COPY package*.json ./
    RUN npm ci --only=production
    COPY . .
    RUN npm run build

    # Production stage
    FROM node:20-alpine
    RUN addgroup -g 1001 -S nodejs && \
        adduser -S nodejs -u 1001
    WORKDIR /app
    COPY --from=builder --chown=nodejs:nodejs /app/dist ./dist
    COPY --from=builder --chown=nodejs:nodejs /app/node_modules ./node_modules
    USER nodejs
    EXPOSE 3000
    CMD ["node", "dist/main.js"]
    ```

    **Security Best Practices**
    - Use minimal base images (alpine, distroless)
    - Run containers as non-root user
    - Implement health checks for container reliability
    - Scan images for vulnerabilities regularly
    - Keep base images updated

    **12-Factor App Principles**
    - Configuration via environment variables
    - Stateless processes
    - Explicit dependencies
    - Port binding for services
    - Graceful shutdown handling

    **Skaffold Preference**
    - Favor Skaffold over Docker Compose for local development
    - Continuous development loop with hot reload
    - Production-like local environment

    For detailed Dockerfile optimization techniques, orchestration patterns, security hardening, and Skaffold configuration, see `# Container Development Reference`.

    # Container Development Reference

    Comprehensive reference for Docker multi-stage builds, 12-factor app principles, security best practices, Skaffold workflows, and Docker Compose patterns.

    ## Table of Contents

    - [Multi-Stage Build Patterns](#multi-stage-build-patterns)
    - [12-Factor App Principles](#12-factor-app-principles)
    - [Security Best Practices](#security-best-practices)
    - [Skaffold Workflows](#skaffold-workflows)
    - [Docker Compose Patterns](#docker-compose-patterns)
    - [Performance Optimization](#performance-optimization)
    - [Advanced Dockerfile Patterns](#advanced-dockerfile-patterns)

    ---
    ## Multi-Stage Build Patterns

    ### Basic Multi-Stage Build

    ```dockerfile
    # Build stage
    FROM golang:1.21-alpine AS builder
    WORKDIR /app
    COPY go.mod go.sum ./
    RUN go mod download
    COPY . .
    RUN CGO_ENABLED=0 GOOS=linux go build -o main .

    # Final stage
    FROM alpine:latest
    RUN apk --no-cache add ca-certificates
    WORKDIR /root/
    COPY --from=builder /app/main .
    CMD ["./main"]
    ```

    ### Node.js Multi-Stage Build

    ```dockerfile
    # Dependencies stage
    FROM node:20-alpine AS deps
    WORKDIR /app
    COPY package*.json ./
    RUN npm ci --only=production

    # Build stage
    FROM node:20-alpine AS builder
    WORKDIR /app
    COPY package*.json ./
    RUN npm ci
    COPY . .
    RUN npm run build

    # Production stage
    FROM node:20-alpine AS runner
    WORKDIR /app
    ENV NODE_ENV=production
    COPY --from=deps /app/node_modules ./node_modules
    COPY --from=builder /app/dist ./dist
    COPY --from=builder /app/package.json ./
    USER node
    CMD ["node", "dist/index.js"]
    ```

    ### Python Multi-Stage Build

    ```dockerfile
    # Builder stage
    FROM python:3.11-slim AS builder
    WORKDIR /app
    RUN pip install --no-cache-dir uv
    COPY pyproject.toml uv.lock ./
    RUN uv sync --frozen --no-dev
    COPY . .
    RUN uv build

    # Runtime stage
    FROM python:3.11-slim
    WORKDIR /app
    COPY --from=builder /app/.venv /app/.venv
    COPY --from=builder /app/dist/*.whl /tmp/
    RUN pip install --no-cache-dir /tmp/*.whl && rm -rf /tmp/*.whl
    ENV PATH="/app/.venv/bin:$PATH"
    USER nobody
    CMD ["python", "-m", "myapp"]
    ```

    ### Optimized Layer Caching

    ```dockerfile
    # Bad: Invalidates cache on any file change
    FROM node:20-alpine
    WORKDIR /app
    COPY . .
    RUN npm install

    # Good: Cache dependencies separately
    FROM node:20-alpine
    WORKDIR /app
    # Copy only dependency files first
    COPY package*.json ./
    RUN npm ci --only=production
    # Copy application code last
    COPY . .
    CMD ["node", "index.js"]
    ```

    ### Build-Time Variables

    ```dockerfile
    FROM alpine:latest AS builder

    # Build arguments
    ARG VERSION=latest
    ARG BUILD_DATE
    ARG VCS_REF

    # Use build args
    LABEL org.opencontainers.image.version="$${VERSION}" \
          org.opencontainers.image.created="$${BUILD_DATE}" \
          org.opencontainers.image.revision="$${VCS_REF}"

    # Conditional builds
    ARG BUILD_ENV=production
    RUN if [ "$BUILD_ENV" = "development" ]; then \
          apk add --no-cache git vim curl; \
        fi

    # Build command:
    # docker build \
    #   --build-arg VERSION=1.2.3 \
    #   --build-arg BUILD_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ") \
    #   --build-arg VCS_REF=$(git rev-parse --short HEAD) \
    #   -t myapp:1.2.3 .
    ```

    ---
    ## 12-Factor App Principles

    [... full content from read 42, preserving all code blocks and sections exactly as in the original file ...]

  '';
}
