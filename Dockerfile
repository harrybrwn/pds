FROM node:22.4.1-alpine3.20 AS build
RUN npm install --global pnpm
WORKDIR /app
# cache dependencies
COPY package.json pnpm-lock.yaml ./
COPY scripts/postinstall.sh ./scripts/
RUN pnpm install --frozen-lockfile
# full build
COPY . .
RUN pnpm build

FROM node:22.4.1-alpine3.20
COPY --from=build /app/node_modules /app/node_modules
COPY --from=build /app/dist /app/dist
COPY scripts/pdsadmin.sh /usr/bin/pdsadmin
WORKDIR /app
ENTRYPOINT [ "node", "--enable-source-maps", "/app/dist/index.js" ]
