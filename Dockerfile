# ── Stage 1: builder ──────────────────────
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci                     # deterministic install
COPY . .
RUN npm test                   # fail the build if tests fail

# ── Stage 2: runtime ─────────────────────
FROM node:20-alpine AS runtime
ENV NODE_ENV=production
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev          # production deps only
COPY --from=builder /app/src ./src
EXPOSE 3000
USER node                      # never run as root
CMD ["node", "src/server.js"]