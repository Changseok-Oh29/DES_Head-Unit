# Multi-stage build for PDCApp containerization
# Stage 1: Build environment
FROM ubuntu:22.04 AS builder

# Avoid interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    git \
    pkg-config \
    qtbase5-dev \
    qtdeclarative5-dev \
    qtquickcontrols2-5-dev \
    libqt5network5 \
    libboost-all-dev \
    libboost-system-dev \
    libboost-thread-dev \
    libboost-filesystem-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# Copy dependencies source code (from git submodules)
COPY ./deps/vsomeip /build/vsomeip
COPY ./deps/capicxx-core-runtime /build/capicxx-core-runtime
COPY ./deps/capicxx-someip-runtime /build/capicxx-someip-runtime

# Build vsomeip from local source
WORKDIR /build/vsomeip
RUN mkdir -p build && cd build && \
    cmake -DCMAKE_INSTALL_PREFIX=/usr/local .. && \
    make -j$(nproc) && \
    make install && \
    ldconfig

# Build CommonAPI Core from local source
WORKDIR /build/capicxx-core-runtime
RUN mkdir -p build && cd build && \
    cmake -DCMAKE_INSTALL_PREFIX=/usr/local .. && \
    make -j$(nproc) && \
    make install && \
    ldconfig

# Build CommonAPI SomeIP from local source
WORKDIR /build/capicxx-someip-runtime
RUN mkdir -p build && cd build && \
    cmake -DCMAKE_INSTALL_PREFIX=/usr/local -DUSE_INSTALLED_COMMONAPI=ON .. && \
    make -j$(nproc) && \
    make install && \
    ldconfig

# Copy application source code
COPY ./app/PDCApp /build/PDCApp

# Copy CommonAPI generated code
COPY ./commonapi/generated /build/commonapi/generated

# Build PDCApp
WORKDIR /build/PDCApp
RUN rm -rf build && mkdir -p build && cd build && \
    cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCOMMONAPI_GEN_DIR=/build/commonapi/generated \
    -DCMAKE_PREFIX_PATH=/usr/local \
    && make -j$(nproc)

# Stage 2: Runtime environment
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install runtime dependencies only
RUN apt-get update && apt-get install -y \
    qtbase5-dev \
    qtdeclarative5-dev \
    qtquickcontrols2-5-dev \
    libqt5network5 \
    libqt5quick5 \
    libqt5qml5 \
    libqt5widgets5 \
    libqt5gui5 \
    qml-module-qtquick2 \
    qml-module-qtquick-window2 \
    qml-module-qtquick-controls2 \
    qml-module-qtquick-layouts \
    libboost-system1.74.0 \
    libboost-thread1.74.0 \
    libboost-filesystem1.74.0 \
    && rm -rf /var/lib/apt/lists/*

# Copy vsomeip and CommonAPI libraries from builder
COPY --from=builder /usr/local/lib/libvsomeip3* /usr/local/lib/
COPY --from=builder /usr/local/lib/libCommonAPI* /usr/local/lib/

# Update library cache
RUN ldconfig

# Create app directory
WORKDIR /app

# Copy built executable from builder stage
COPY --from=builder /build/PDCApp/build/PDCApp /app/
COPY --from=builder /build/PDCApp/config /app/config
COPY --from=builder /build/PDCApp/asset /app/asset

# Set up vsomeip configuration
ENV VSOMEIP_CONFIGURATION=/app/config/vsomeip.json
ENV VSOMEIP_APPLICATION_NAME=PDCApp
ENV LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH

# For Qt GUI display
ENV QT_QPA_PLATFORM=eglfs
ENV QT_QPA_EGLFS_INTEGRATION=eglfs_kms

# Expose vsomeip ports (adjust as needed)
EXPOSE 30490-30510/tcp
EXPOSE 30490-30510/udp

# Run the application
CMD ["/app/PDCApp"]
