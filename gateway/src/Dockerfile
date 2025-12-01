FROM node:18-alpine AS builder

WORKDIR /app

COPY package*.json ./

RUN npm ci --production

COPY . .

RUN npm run build

FROM node:18-alpine AS production

RUN addgroup -g 1001 -S nodejs && adduser -S backend -u 1001

COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules

RUN chown -R backend:nodejs /app

USER backend

EXPOSE 5921

CMD ["npm", "start"]