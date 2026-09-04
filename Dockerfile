# Pin the toolchain for reproducible builds. Bump deliberately and verify the
# wasm still links (the Makefile uses em++ because recent emsdk links object-only
# inputs as C) and that every notation format still renders.
FROM docker.io/emscripten/emsdk:6.0.9

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal
ENV PATH="/root/.cargo/bin:${PATH}"
RUN cargo install wasi-stub --version 0.3.1

# Install a pinned official binaryen release into /usr/local/bin (on PATH) for
# the Makefile's explicit wasm-opt pass. Older binaryen miscompiled the EsAC
# path; 132 is the current release and matches the toolchain used to build the
# committed wasm.
ARG BINARYEN_VERSION=132
RUN curl -sL https://github.com/WebAssembly/binaryen/releases/download/version_${BINARYEN_VERSION}/binaryen-version_${BINARYEN_VERSION}-x86_64-linux.tar.gz \
    | tar xz -C /usr/local/bin --strip-components=2 binaryen-version_${BINARYEN_VERSION}/bin/wasm-opt

WORKDIR /src
