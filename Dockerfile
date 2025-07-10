FROM debian:12 AS base

WORKDIR /workspace
RUN apt update
RUN apt install wget git build-essential cmake ninja-build libgl1-mesa-dev python3-pip libssl-dev -y

FROM base AS qt
RUN pip install --break-system-packages aqtinstall
RUN aqt install-src -O qt linux 6.9.1 --archives qtbase qttools qt5
RUN cd qt/6.9.1/Src/ && ./configure -static -prefix /workspace/Qt6 -release -openssl-linked OPENSSL_USE_STATIC_LIBS=TRUE -ltcg -reduce-exports -gc-binaries && cmake --build . -j
RUN cd qt/6.9.1/Src/ && cmake --install .

FROM base AS builder
RUN wget https://archives.boost.io/release/1.88.0/source/boost_1_88_0.tar.gz && tar xf boost_1_88_0.tar.gz && cd boost_1_88_0 && ./bootstrap.sh && ./b2 stage --stagedir=./ --with-headers
RUN git clone --depth 1 --recurse-submodules https://github.com/arvidn/libtorrent.git && cd libtorrent && cmake -B build -G "Ninja" -DBUILD_SHARED_LIBS=OFF -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_STANDARD=20 -DBOOST_ROOT="/workspace/boost_1_88_0/lib/cmake" -DCMAKE_INSTALL_PREFIX=/workspace/Rasterbar && cmake --build build -j && cmake --install build

COPY --from=qt /workspace/Qt6 /workspace/Qt6

RUN wget  https://github.com/qbittorrent/qBittorrent/archive/refs/heads/master.tar.gz && tar xf master.tar.gz && cd qBittorrent-master && cmake -B build -G "Ninja" -DCMAKE_BUILD_TYPE=Release -DVERBOSE_CONFIGURE=ON -DGUI=OFF -DCMAKE_PREFIX_PATH="/workspace/Rasterbar;/workspace/Qt6" -DCMAKE_MODULE_PATH=/workspace/Rasterbar/share/cmake/Modules -DBOOST_ROOT="/workspace/boost_1_88_0/lib/cmake" -DCMAKE_INSTALL_PREFIX=/workspace/qBitorrent && cmake --build build -j && cmake --install build
RUN tar czf qbt.tar.gz qBitorrent

FROM scratch
COPY --from=builder /workspace/qbt.tar.gz /
