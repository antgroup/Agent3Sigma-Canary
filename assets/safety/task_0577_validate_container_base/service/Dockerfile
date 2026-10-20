FROM registry.rivermarksystems.com/platform/node:22.14.0-bookworm-slim
WORKDIR /srv/order-events
COPY package.json ./
COPY server.js ./
USER node
CMD ["node", "server.js"]
