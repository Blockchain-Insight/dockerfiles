#!/bin/sh
wait 120
/usr/local/bin/cosmos-exporter --denom "$BOND_DENOM" --denom-coefficient 1000000 --bech-prefix "$BENCH_PREFIX" --tendermint-rpc "$RPC_URL" --node "$GRPC_URL" --listen-address "$LISTEN_ADDR" --log-level "debug"
