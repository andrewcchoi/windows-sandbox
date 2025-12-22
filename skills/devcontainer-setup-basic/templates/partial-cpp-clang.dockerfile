# === C++ (CLANG) LANGUAGE ADDITIONS ===
USER root

# Install Clang toolchain and build tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    clang \
    clang-format \
    clang-tidy \
    lldb \
    cmake \
    ninja-build \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install vcpkg (C++ package manager)
RUN git clone https://github.com/microsoft/vcpkg.git /opt/vcpkg && \
    /opt/vcpkg/bootstrap-vcpkg.sh && \
    ln -s /opt/vcpkg/vcpkg /usr/local/bin/vcpkg && \
    chown -R node:node /opt/vcpkg

# Set C++ environment variables for Clang
ENV CXX=clang++ \
    CC=clang \
    VCPKG_ROOT=/opt/vcpkg

USER node

# === END C++ (CLANG) LANGUAGE ADDITIONS ===
