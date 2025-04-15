#!/bin/bash
set -ex

# Get number of CPU cores for parallel build
NPROC=$(nproc)

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
  -DUSE_SYSTEM_BPF_BCC=ON

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
