FROM node:22.4.1-alpine3.20 AS build
RUN npm install --global pnpm
WORKDIR /app
# cache dependencies
COPY package.json pnpm-lock.yaml ./
RUN pnpm approve-builds && pnpm install --frozen-lockfile
# full build
COPY . .
RUN pnpm build

FROM node:22.4.1-alpine3.20 AS pds
RUN apk add --update bash
COPY --from=build /app/node_modules /app/node_modules
COPY --from=build /app/dist /app/dist
WORKDIR /app
ENTRYPOINT [ "node", "--enable-source-maps", "/app/dist/index.js" ]

FROM alpine:3.20 AS pdsadmin
RUN apk update && apk upgrade && \
    apk add -l -U \
        bash      \
        curl      \
        jq        \
        openssl
COPY scripts/pdsadmin.sh /usr/bin/pdsadmin
ENTRYPOINT [ "/usr/bin/pdsadmin" ]
