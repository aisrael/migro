FROM alpine:edge as builder
RUN apk add --update crystal shards openssl-dev yaml-dev libxml2-dev musl-dev
RUN mkdir /migro
WORKDIR /migro
COPY shard.* /migro/
RUN shards update
COPY . /migro/
# Workaround until shards 0.8.1
# RUN shards build --release
RUN crystal build --release src/migro.cr

FROM alpine:edge
RUN apk add --update crystal openssl yaml pcre gc libevent libgcc
# COPY --from=builder /migro/bin/migro /bin/
COPY --from=builder /migro/migro /usr/bin/
ENTRYPOINT [ "/usr/bin/migro" ]
