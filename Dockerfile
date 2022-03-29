ARG GO_VERSION=1.17
ARG XX_VERSION=1.1.0

FROM --platform=$BUILDPLATFORM tonistiigi/xx:${XX_VERSION} AS xx

FROM --platform=$BUILDPLATFORM golang:${GO_VERSION}-alpine as builder

# Copy the build utilities.
COPY --from=xx / /

ARG TARGETPLATFORM

WORKDIR /workspace

# copy api submodule
COPY api/ api/

# copy modules manifests
COPY go.mod go.mod
COPY go.sum go.sum

# cache modules
RUN go mod download

# copy source code
COPY main.go main.go
COPY controllers/ controllers/
COPY internal/ internal/

# build
ENV CGO_ENABLED=0
RUN xx-go build -a -o notification-controller main.go

FROM registry.access.redhat.com/ubi8/ubi

LABEL org.opencontainers.image.source="https://github.com/fluxcd/notification-controller"

ARG TARGETPLATFORM
RUN yum install -y ca-certificates

COPY --from=builder /workspace/notification-controller /usr/local/bin/

USER 65534:65534

ENTRYPOINT [ "notification-controller" ]
