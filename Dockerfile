FROM alpine:3.8 as buildstage

RUN mkdir -p /src  && mkdir -p /opt && mkdir -p /nodejs
RUN NPROC=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1) && \
    echo "@testing http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
    apk update && \
    apk upgrade && \
    apk add git cmake wget make libc-dev gcc g++ bzip2-dev boost-dev zlib-dev expat-dev lua5.2-dev libtbb@testing libtbb-dev@testing nodejs npm libstdc++ 

RUN git clone https://github.com/Project-OSRM/osrm-backend.git && \
    cd osrm-backend && \
    git checkout v5.19.0 && \
    cd -

RUN cd osrm-backend && \
    npm install && \
    mkdir -p build && \
    cd build && \
    cmake .. -DCMAKE_BUILD_TYPE=Release -DENABLE_NODE_BINDINGS=On && \
    cmake --build . && \
    make install && \
    cd ../profiles && \
    cp -r * /opt && \
    strip /usr/local/bin/*

    # rm -rf /src /usr/local/lib/libosrm*


# Multistage build to reduce image size - https://docs.docker.com/engine/userguide/eng-image/multistage-build/#use-multi-stage-builds
# Only the content below ends up in the image, this helps remove /src from the image (which is large)
# FROM node:8-alpine as runstage
FROM alpine:3.8 as runstage
RUN mkdir -p /src  && mkdir -p /opt && mkdir -p /nodejs
RUN echo "@testing http://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories && \
    apk update && \
    apk add boost-filesystem boost-program_options boost-regex boost-iostreams boost-thread libgomp lua5.2 expat libtbb@testing nodejs npm libstdc++
COPY --from=buildstage /usr/local /usr/local
COPY --from=buildstage /opt /opt
COPY --from=buildstage /osrm-backend/lib/binding/ /osrm
# WORKDIR /opt

# EXPOSE 5000