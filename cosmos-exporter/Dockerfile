# Use the official Golang base image
FROM golang:1.17-alpine3.14 as builder
# Install dependencies
RUN apk add --no-cache git
# Set the working directory
WORKDIR /app
# Download and build cosmos-exporter
RUN git clone https://github.com/solarlabsteam/cosmos-exporter.git /app
RUN go build -o /app/cosmos-exporter
# Start from the Alpine base image
FROM alpine:3.14
# Install ca-certificates
RUN apk add --no-cache ca-certificates
# Copy the binary from the builder stage
COPY --from=builder /app/cosmos-exporter /usr/local/bin/cosmos-exporter
# Expose the exporter port
EXPOSE 9300
