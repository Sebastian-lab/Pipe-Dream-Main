ARG VITE_API_KEY
FROM node:20-slim AS base
ARG VITE_API_KEY
WORKDIR /app
ENV VITE_API_KEY=${VITE_API_KEY}
COPY package*.json .
RUN npm install
COPY . .

FROM base AS development
EXPOSE 5173
CMD ["npm", "run", "dev", "--", "--host"]

FROM base AS builder
RUN npm run build

FROM nginx:alpine AS nginx
COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/nginx.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
