FROM golang:1.19-alpine as builder
WORKDIR /build
ADD . .
ARG SHA1="[no-sha]"
ARG TAG="[no-tag]"
ARG GOARCH="amd64"

RUN apk --no-cache add ca-certificates git
RUN BUILD_DATE=$(date +%F-%T) CGO_ENABLED=0 GOOS=linux GOARCH=$GOARCH go build -o /redis_exporter \
    -ldflags  "-s -w -extldflags \"-static\" -X main.BuildVersion=$TAG -X main.BuildCommitSha=$SHA1 -X main.BuildDate=$BUILD_DATE" .

RUN [ "$GOARCH" = "amd64" ]  && /redis_exporter -version || ls -la /redis_exporter


FROM alpine as alpine

COPY --from=builder /redis_exporter /redis_exporter
COPY --from=builder /etc/ssl/certs /etc/ssl/certs

# Run as non-root user for secure environments
USER 59000:59000

EXPOSE     9121
ENTRYPOINT [ "/redis_exporter" ]
