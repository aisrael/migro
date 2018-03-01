FROM crystallang/crystal as builder
RUN mkdir /migro
WORKDIR /migro
COPY shard.* /migro/
RUN shards
COPY . /migro/
RUN shards build --release --static

FROM ubuntu:16.04
COPY --from=builder /migro/bin/migro /bin/
ENTRYPOINT [ "/bin/migro" ]
