FROM huaouo/dev_cuda:latest AS builder
COPY build-deps.sh /
RUN bash build-deps.sh

FROM huaouo/dev_cuda:latest
COPY --from=builder /mapd-deps.tar.xz /
COPY install-deps.sh /
RUN bash /install-deps.sh && rm /mapd-deps.tar.xz /install-deps.sh
