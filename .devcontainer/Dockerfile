# Generated using sandbox-maxxing plugin Intermediate mode
# Development container for plugin development with services
# Includes PostgreSQL, Redis, RabbitMQ for testing examples

# Stage 1: Get Node.js from official image (Issue #29)
FROM node:20-slim AS node-source

# Stage 2: Get Python + uv from official Astral image
FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim

# Stage 3: Main build
FROM node:20-bookworm-slim

# Timezeone configuration
ARG TZ=America/Los_Angeles
ENV TZ="$TZ"


# Install system packages including iptables for firewall
RUN apt-get update && apt-get install -y --no-install-recommends \
  # Core utilities
  git vim nano less procps sudo unzip wget curl ca-certificates gnupg gnupg2 \
  # JSON processing and manual pages
  jq man-db \
  # Shell and CLI enhancements
  zsh fzf \
  # GitHub CLI
  gh \
  # Network security tools (firewall)
  iptables ipset iproute2 dnsutils \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Copy Node.js from official image (Issue #29 - avoids NodeSource SSL issues)
COPY --from=node-source /usr/local/bin/node /usr/local/bin/
COPY --from=node-source /usr/local/lib/node_modules /usr/local/lib/node_modules
RUN ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm && \
    ln -s /usr/local/lib/node_modules/npm/bin/npx-cli.js /usr/local/bin/npx

# Copy Python 3.12 binaries
COPY --from=python-uv-source /usr/local/bin/python3* /usr/local/bin/
COPY --from=python-uv-source /usr/local/lib/python3.12 /usr/local/lib/python3.12
COPY --from=python-uv-source /usr/local/bin/pip* /usr/local/bin/
RUN ln -sf /usr/local/bin/python3.12 /usr/local/bin/python && \
    ln -sf /usr/local/bin/python3.12 /usr/local/bin/python3

# Copy uv and uvx binaries
COPY --from=python-uv-source /usr/local/bin/uv /usr/local/bin/
COPY --from=python-uv-source /usr/local/bin/uvx /usr/local/bin/

# Python packages
RUN apt-get update && apt-get install -y --no-install-recommends \
  python3-full \
  python3-pip \
  python3-venv \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Database clients
RUN apt-get update && apt-get install -y --no-install-recommends \
  postgresql-client \
  mysql-client \
  sqlite3 \
  redis-tools \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Create node user if it doesn't exist (may already exist in base image)
RUN if ! id -u node > /dev/null 2>&1; then \
  groupadd --gid 1000 node && \
  useradd --uid 1000 --gid node --shell /bin/bash --create-home node; \
fi

RUN mkdir -p /usr/local/share/npm-global && \
  chown -R node:node /usr/local/share

# Persistent bash history
RUN mkdir /commandhistory && \
  touch /commandhistory/.bash_history && \
  chown -R node /commandhistory

ENV DEVCONTAINER=true

# Create workspace and config directories
RUN mkdir -p /workspace /home/node/.claude && \
  chown -R node:node /workspace /home/node/.claude

WORKDIR /workspace

# GIT delta (enhanced git diff)
ARG GIT_DELTA_VERSION=0.18.2
RUN ARCH=$(dpkg --print-architecture) && \
  wget "https://github.com/dandavison/delta/releases/download/${GIT_DELTA_VERSION}/git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb" && \
  dpkg -i "git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb" && \
  rm "git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb"

# Setup npm registry allowlist for Claude Code updates (Issue #32)
RUN echo "registry.npmjs.org" >> /etc/claude-allowed-domains.txt && \
    echo "npmjs.org" >> /etc/claude-allowed-domains.txt

USER node

# NPM global config
ENV NPM_CONFIG_PREFIX=/usr/local/share/npm-global
ENV PATH=$PATH:/usr/local/share/npm-global/bin

# ZSH with Powerlevel10k
ARG ZSH_IN_DOCKER_VERSION=1.2.0
ENV SHELL=/bin/zsh

RUN sh -c "$(wget -O- https://github.com/deluan/zsh-in-docker/releases/download/v${ZSH_IN_DOCKER_VERSION}/zsh-in-docker.sh)" -- \
  -p git -p fzf \
  -a "source /usr/share/doc/fzf/examples/key-bindings.zsh" \
  -a "source /usr/share/doc/fzf/examples/completion.zsh" \
  -a "export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history" \
  -x

# Editor configuration
ENV EDITOR=nano
ENV VISUAL=nano

# Python uv environment
ENV UV_COMPILE_BYTECODE=1
ENV UV_LINK_MODE=copy
ENV PATH="/workspace/.venv/bin:$PATH"
RUN uv add --system deepagents tavily-python
RUN uv add --no-cache-dir \
  pytest \
  black \
  flake8 \
  mypy \
  ipython \
  requests

# Install Claude Code
ARG CLAUDE_CODE_VERSION=latest
RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}
RUN npm install -g \
  typescript \
  ts-node \
  eslint \
  prettier \
  nodemon

# The langgraph.json file has the assistant ID as the key:
#   "graphs": {
#     "research": "./agent.py:agent"
#   },

# export ANTHROPIC_API_KEY=your_anthropic_api_key_here  # Required for Claude model
# export GOOGLE_API_KEY=your_google_api_key_here        # Required for Gemini model ([get one here](https://ai.google.dev/gemini-api/docs))
# export TAVILY_API_KEY=your_tavily_api_key_here        # Required for web search ([get one here](https://www.tavily.com/)) with a generous free tier
# export LANGSMITH_API_KEY=your_langsmith_api_key_here  # [LangSmith API key](https://smith.langchain.com/settings) (free to sign up)
# export NEXT_PUBLIC_LANGSMITH_API_KEY="lsv2_xxxx"

# $ git clone https://github.com/langchain-ai/deepagents-quickstarts.git
# $ cd deepagents-quickstarts/deep_research
# $ uv build
# $ langgraph dev

# deep-agents-ui configuration 
# env.local settings
# NEXT_PUBLIC_DEPLOYMENT_URL="http://127.0.0.1:2024"
# NEXT_PUBLIC_AGENT_ID="research"

# $ git clone https://github.com/langchain-ai/deep-agents-ui.git
# $ cd deep-agents-ui
# $ yarn install
# $ yarn dev

# ╦  ┌─┐┌┐┌┌─┐╔═╗┬─┐┌─┐┌─┐┬ ┬
# ║  ├─┤││││ ┬║ ╦├┬┘├─┤├─┘├─┤
# ╩═╝┴ ┴┘└┘└─┘╚═╝┴└─┴ ┴┴  ┴ ┴

# - 🚀 API: http://127.0.0.1:2024
# - 🎨 Studio UI: https://smith.langchain.com/studio/?baseUrl=http://127.0.0.1:2024
# - 📚 API Docs: http://127.0.0.1:2024/docs
# - ⚙️ Deepagents UI: http://localhost:3000
# ...

# Firewall initialization script
COPY .devcontainer/init-firewall.sh /usr/local/bin/
USER root
RUN chmod +x /usr/local/bin/init-firewall.sh && \
  echo "node ALL=(root) NOPASSWD: /usr/local/bin/init-firewall.sh" > /etc/sudoers.d/node-firewall && \
  chmod 0440 /etc/sudoers.d/node-firewall
USER node

# Set the default command
CMD ["/bin/zsh"]