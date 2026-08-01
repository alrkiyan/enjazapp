# Stage 1: Build the app
FROM node:22-alpine AS builder

# Bun is the package manager/script runner for this project (bun.lock is the
# only lockfile); Node stays the runtime that actually executes vite via its
# shebang when `bun run build` invokes it.
COPY --from=oven/bun:1-alpine /usr/local/bin/bun /usr/local/bin/bun

WORKDIR /app

# Copy package files first for better layer caching
COPY package.json bun.lock ./

# Install dependencies
RUN bun install --frozen-lockfile

# Copy source code
COPY . .

# Build args for Vite env vars (baked in at build time).
# In Coolify: set these two as env vars and tick "Build Variable" so they are
# passed as --build-args. Convert ARG -> ENV so `vite build` (which reads
# process.env for VITE_* keys) actually picks them up.
ARG VITE_SUPABASE_URL
ARG VITE_SUPABASE_ANON_KEY
ENV VITE_SUPABASE_URL=$VITE_SUPABASE_URL
ENV VITE_SUPABASE_ANON_KEY=$VITE_SUPABASE_ANON_KEY

# Build the app
RUN bun run build

# Stage 2: Serve with Nginx
FROM nginx:alpine

# Remove default nginx config
RUN rm /etc/nginx/conf.d/default.conf

# Copy custom nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy built files from builder stage
COPY --from=builder /app/dist /usr/share/nginx/html

# Expose port 80
EXPOSE 80

# Health check.
# Use 127.0.0.1 (not "localhost") to force IPv4: the custom nginx.conf listens
# on IPv4 only, while "localhost" resolves to IPv6 (::1) first -> connection
# refused, which made Coolify mark the container unhealthy and roll back.
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://127.0.0.1/health || exit 1

CMD ["nginx", "-g", "daemon off;"]
