FROM ysbaddaden/crystal-alpine:0.24.1 as builder
RUN mkdir /migro
WORKDIR /migro
RUN apk add --update openssl-dev yaml-dev libxml2-dev
COPY shard.* /migro/
RUN shards
COPY . /migro/
RUN shards build --release

FROM alpine:3.7
RUN apk add --update openssl yaml pcre gc libevent libgcc
COPY --from=builder /migro/bin/migro /bin/
ENTRYPOINT [ "/bin/migro" ]
