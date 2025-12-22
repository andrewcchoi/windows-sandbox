# === GO LANGUAGE ADDITIONS ===
USER root

# Install Go
ARG GO_VERSION=1.22.0
RUN wget -O go.tar.gz "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" && \
    tar -C /usr/local -xzf go.tar.gz && \
    rm go.tar.gz

# Set Go environment variables
ENV GOPATH=/home/node/go \
    GOBIN=/home/node/go/bin \
    PATH=$PATH:/usr/local/go/bin:/home/node/go/bin \
    GO111MODULE=on \
    CGO_ENABLED=1

# Create Go directories for non-root user
RUN mkdir -p /home/node/go/bin /home/node/go/pkg /home/node/go/src && \
    chown -R node:node /home/node/go

USER node

# Install Go development tools
RUN go install golang.org/x/tools/gopls@latest && \
    go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest && \
    go install golang.org/x/tools/cmd/goimports@latest && \
    go install github.com/go-delve/delve/cmd/dlv@latest

# === END GO LANGUAGE ADDITIONS ===
