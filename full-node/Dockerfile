# Use the official golang image as base
FROM golang:1.19.8

# Update system and install build tools
RUN apt -q update && \
    apt -qy install curl make git jq lz4 build-essential && \
    apt -qy upgrade

# Expose Ports
EXPOSE 26657 1317 9090 9091 26656 9100 26660
