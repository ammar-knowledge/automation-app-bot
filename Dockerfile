FROM node:22.12-bookworm-slim

WORKDIR /app

COPY package*.json ./
RUN npm install --ignore-scripts

COPY . .

ENV PORT=${PORT:-10179}
USER default:65a6VA4oQeGUiDX7dYeoZM5QZlCeOvsj

CMD ./node_modules/probot/bin/probot.js run --port $PORT ./index.js
