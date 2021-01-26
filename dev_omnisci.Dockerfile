FROM huaouo/dev_cuda:latest

COPY mapd-deps-prebuilt.sh /
RUN bash /mapd-deps-prebuilt.sh && rm /mapd-deps-prebuilt.sh
