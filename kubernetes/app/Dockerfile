# api-service container image.
FROM node:18-slim

WORKDIR /app

# Copy package.json first so npm install is cached independently of source changes.
COPY package.json ./

# Install only what's needed at runtime.
RUN apt-get update \
 && apt-get install -y --no-install-recommends curl \
 && rm -rf /var/lib/apt/lists/* \
 && npm install --omit=dev

# Application code.
COPY server.js ./

# Secrets must NOT be baked into the image. MONGO_URI comes from a Kubernetes Secret at runtime.

EXPOSE 3000

# Run as the non-root "node" user.
USER node

CMD ["npm", "start"]
