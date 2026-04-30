FROM node:18-slim

RUN apt-get update && \
    apt-get install -y lua5.1 && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY . .
RUN cd web && npm install

EXPOSE 3000
CMD ["node", "web/server.js"]
