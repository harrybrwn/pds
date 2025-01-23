ARG NGINX_VERSION=1.27.3-alpine3.20

FROM node:22.4.1-alpine3.20 AS build
RUN npm install -g pnpm
WORKDIR /app
# cache dependencies
COPY package.json ./
COPY pkg ./pkg
RUN pnpm install
# full build
COPY . .
RUN pnpm build

FROM nginx:${NGINX_VERSION}
RUN cat <<EOF > /etc/nginx/conf.d/pdsls.conf
server {
    listen 8080;
    server_tokens off;

    location / {
        root /app/dist;
    }
}
EOF
COPY --from=build /app/dist /app/dist
