FROM node:22-alpine
WORKDIR /srv/payment
COPY package*.json ./
RUN npm ci --omit=dev
COPY . .
EXPOSE 8443
CMD ["node","server.js"]
