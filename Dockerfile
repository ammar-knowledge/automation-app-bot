FROM node:20

WORKDIR /app

COPY package*.json ./
RUN npm ci --omit=dev

COPY . .

ENV PORT=${PORT:-3000}
USER 1000:1000

CMD ./node_modules/probot/bin/probot.js run --port $PORT ./index.js
