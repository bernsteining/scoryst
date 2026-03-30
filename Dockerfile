FROM docker.io/emscripten/emsdk:latest

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal
ENV PATH="/root/.cargo/bin:${PATH}"
RUN cargo install wasi-stub

# Install official binaryen release (overrides emsdk's patched version for reproducible builds)
ARG BINARYEN_VERSION=128
RUN curl -sL https://github.com/WebAssembly/binaryen/releases/download/version_${BINARYEN_VERSION}/binaryen-version_${BINARYEN_VERSION}-x86_64-linux.tar.gz \
    | tar xz -C /usr/local/bin --strip-components=2 binaryen-version_${BINARYEN_VERSION}/bin/wasm-opt

WORKDIR /src
