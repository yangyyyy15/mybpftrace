#!/bin/bash
set -ex

# Get number of CPU cores for parallel build
NPROC=$(nproc)

# Display BCC version and paths
echo "BCC information:"
find /usr -name bcc_version.h || echo "bcc_version.h not found"
find /usr -name libbcc.a || echo "libbcc.a not found"
find /usr -name libbcc.so || echo "libbcc.so not found"

# If BCC was built from source, create symlinks if needed
if [ ! -f "/usr/lib/libbcc.a" ] && [ -f "/usr/lib/x86_64-linux-gnu/libbcc.a" ]; then
    ln -s /usr/lib/x86_64-linux-gnu/libbcc.a /usr/lib/libbcc.a
fi

if [ ! -f "/usr/lib/libbcc_bpf.a" ] && [ -f "/usr/lib/x86_64-linux-gnu/libbcc_bpf.a" ]; then
    ln -s /usr/lib/x86_64-linux-gnu/libbcc_bpf.a /usr/lib/libbcc_bpf.a
fi

# Create a build directory
mkdir -p build

# Run CMake configuration with static linking enabled
cd build
cmake .. \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_VERBOSE_MAKEFILE=ON \
  -DBUILD_TESTING=OFF \
  -DSTATIC_LINKING=ON \
  -DENABLE_MAN=OFF \
  -DUSE_SYSTEM_BPF_BCC=ON \
  -DLIBBCC_INCLUDE_DIRS=/usr/include \
  -DLIBBCC_LIBRARIES=/usr/lib/libbcc.a

# Build bpftrace
make -j${NPROC}

# Check if the binary was successfully built
if [ -f "src/bpftrace" ]; then
  echo "Build successful!"
  
  # Show binary info
  file src/bpftrace
  
  # Verify static linking with musl
  echo "Checking library dependencies:"
  ldd src/bpftrace || echo "No dynamic dependencies (fully static)"
  
  # Create release package
  mkdir -p release/aarch64
  cp src/bpftrace release/aarch64/
  
  # Copy tools if available
  if [ -d "../tools" ]; then
    cp -r ../tools release/aarch64/
    chmod +x release/aarch64/tools/*.bt 2>/dev/null || true
  fi
  
  # Create tarball 
  cd release
  tar -czf /bpftrace/bpftrace-alpine-static.tar.gz aarch64
  echo "Package created: bpftrace-alpine-static.tar.gz"
  
  exit 0
else
  echo "Build failed - bpftrace binary not found!"
  exit 1
fi
