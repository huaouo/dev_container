FROM huaouo/dev_cuda:latest AS builder
COPY build-deps.sh /
COPY ARROW-10651-fix-alloc-dealloc-mismatch.patch /
COPY llvm-9-glibc-2.31-708430.patch /
RUN bash build-deps.sh

FROM huaouo/dev_cuda:latest
COPY --from=builder /usr/local/mapd-deps /usr/local/mapd-deps
COPY install-deps.sh /
RUN bash /install-deps.sh && rm /install-deps.sh
