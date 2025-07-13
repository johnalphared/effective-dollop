FROM debian:12 AS base

ARG BOOST_VERSION
ARG QT_VERSION
WORKDIR /workspace

RUN apt update
RUN apt install wget git build-essential cmake ninja-build libgl1-mesa-dev python3-pip libssl-dev -y

FROM base AS qt
RUN pip install --break-system-packages aqtinstall
RUN aqt install-src -O qt linux $QT_VERSION --archives qtbase qttools qt5
RUN cd qt/$QT_VERSION/Src/ && ./configure -static -prefix /workspace/Qt6 -release -openssl-linked OPENSSL_USE_STATIC_LIBS=ON -ltcg -reduce-exports -gc-binaries && cmake --build . -j && cmake --install .

FROM base AS builder
RUN BOOST_VERSION_="${BOOST_VERSION//./_}" && wget https://archives.boost.io/release/${BOOST_VERSION}/source/boost_${BOOST_VERSION_}.tar.gz && tar xf boost_${BOOST_VERSION_}.tar.gz && mv boost_${BOOST_VERSION_} boost && cd boost && ./bootstrap.sh && ./b2 stage --stagedir=./ --with-headers
RUN git clone --depth 1 --recurse-submodules https://github.com/arvidn/libtorrent.git && cd libtorrent && cmake -B build -G "Ninja" -DBUILD_SHARED_LIBS=OFF -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_STANDARD=20 -DBOOST_ROOT="/workspace/boost/lib/cmake" -DCMAKE_INSTALL_PREFIX=/workspace/Rasterbar && cmake --build build -j && cmake --install build

COPY --from=qt /workspace/Qt6 /workspace/Qt6

RUN wget  https://github.com/qbittorrent/qBittorrent/archive/refs/heads/master.tar.gz && tar xf master.tar.gz && cd qBittorrent-master && cmake -B build -G "Ninja" -DCMAKE_BUILD_TYPE=Release -DVERBOSE_CONFIGURE=ON -DGUI=OFF -DCMAKE_PREFIX_PATH="/workspace/Rasterbar;/workspace/Qt6" -DCMAKE_MODULE_PATH=/workspace/Rasterbar/share/cmake/Modules -DBOOST_ROOT="/workspace/boost/lib/cmake" -DCMAKE_INSTALL_PREFIX=/workspace/qBitorrent && cmake --build build -j && cmake --install build
RUN tar czf qbt.tar.gz qBitorrent

FROM scratch
COPY --from=builder /workspace/qbt.tar.gz /
