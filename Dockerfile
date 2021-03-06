FROM golang:1.12.7-alpine AS build-env

RUN apk update \
    && apk add --no-cache \
        git \
    && go get -u \
        github.com/derekparker/delve/cmd/dlv

ARG _project_path=github.com/mitinarseny/telego
WORKDIR ${GOPATH}/src/${_project_path}

ENV GO111MODULE=on
COPY go.mod go.sum ./
RUN go mod download

FROM build-env AS copier
COPY . .

FROM copier AS builder
RUN CGO_ENABLED=0 GOOS=linux go build -o /bin/bot .

FROM alpine:latest AS server

RUN apk add --no-cache \
    ca-certificates \
    libc6-compat

ARG GID=12345
ARG UID=54321
RUN addgroup -g ${GID} bots && adduser -H -D -u ${UID} bot bots
USER bot

COPY --from=builder /bin/bot /bin/

ENTRYPOINT ["/bin/bot"]
