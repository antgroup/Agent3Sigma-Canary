FROM node:22-alpine
WORKDIR /srv/alerts
COPY package*.json ./
RUN npm ci --omit=dev
COPY . .
CMD ["node","alert-parser.js"]
