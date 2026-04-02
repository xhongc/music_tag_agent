ARG NODE_IMAGE=node:20-alpine
ARG ALPINE_IMAGE=alpine:3.20

FROM ${NODE_IMAGE} AS builder

ARG TARGETARCH
ENV OPENCODE_VERSION=1.3.13

RUN set -eu; \
    arch="${TARGETARCH:-}"; \
    if [ -z "$arch" ]; then \
      case "$(uname -m)" in \
        x86_64|amd64) arch=amd64 ;; \
        aarch64|arm64) arch=arm64 ;; \
        *) echo "Unable to detect target arch from uname -m: $(uname -m)" >&2; exit 1 ;; \
      esac; \
    fi; \
    case "$arch" in \
      amd64) \
        npm install -g "opencode-linux-x64-musl@${OPENCODE_VERSION}" || npm install -g "opencode-linux-x64-baseline-musl@${OPENCODE_VERSION}"; \
        ;; \
      arm64) \
        npm install -g "opencode-linux-arm64-musl@${OPENCODE_VERSION}"; \
        ;; \
      *) \
        echo "Unsupported TARGETARCH: $arch" >&2; \
        exit 1; \
        ;; \
    esac

RUN set -eu; \
    for candidate in \
      /usr/local/lib/node_modules/opencode-linux-x64-musl/bin/opencode \
      /usr/local/lib/node_modules/opencode-linux-x64-baseline-musl/bin/opencode \
      /usr/local/lib/node_modules/opencode-linux-arm64-musl/bin/opencode; \
    do \
      if [ -x "$candidate" ]; then \
        cp "$candidate" /tmp/opencode-musl; \
        chmod +x /tmp/opencode-musl; \
        exit 0; \
      fi; \
    done; \
    echo "No installed opencode musl binary found" >&2; \
    exit 1

FROM ${ALPINE_IMAGE}

ENV OPENCODE_PORT=9002 \
    OPENCODE_HOSTNAME=0.0.0.0

RUN apk add --no-cache ca-certificates libgcc libstdc++ \
    && addgroup -S opencode \
    && adduser -S -G opencode -h /home/opencode opencode \
    && mkdir -p /home/opencode/app \
    && chown -R opencode:opencode /home/opencode

COPY --from=builder /tmp/opencode-musl /usr/local/bin/opencode
COPY start-opencode-serve.sh /usr/local/bin/start-opencode-serve.sh

RUN chmod +x /usr/local/bin/opencode /usr/local/bin/start-opencode-serve.sh

WORKDIR /home/opencode/app
USER opencode

EXPOSE 4096

CMD ["/usr/local/bin/start-opencode-serve.sh"]
