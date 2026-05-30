# ── Build/deps stage ───────────────────────────────────────────
FROM node:22-alpine AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev

# ── Runtime stage ──────────────────────────────────────────────
FROM node:22-alpine
RUN adduser -D -u 1000 appuser
WORKDIR /app

COPY --from=deps /app/node_modules ./node_modules
COPY src/ ./src/
COPY package.json .

USER appuser
EXPOSE 3000

CMD ["node", "src/app.js"]
