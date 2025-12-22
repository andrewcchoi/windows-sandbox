# === RUST LANGUAGE ADDITIONS ===
USER root

# Install Rust toolchain
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable

# Set Rust environment variables
ENV CARGO_HOME=/home/node/.cargo \
    RUSTUP_HOME=/home/node/.rustup \
    PATH=/home/node/.cargo/bin:$PATH

# Copy cargo configuration to user directory and set ownership
RUN mkdir -p /home/node/.cargo /home/node/.rustup && \
    cp -r /root/.cargo/* /home/node/.cargo/ 2>/dev/null || true && \
    cp -r /root/.rustup/* /home/node/.rustup/ 2>/dev/null || true && \
    chown -R node:node /home/node/.cargo /home/node/.rustup

USER node

# Install Rust components and tools
RUN rustup component add rustfmt clippy rust-src && \
    cargo install cargo-edit cargo-watch cargo-outdated

# === END RUST LANGUAGE ADDITIONS ===
