#!/bin/sh
# Check if MONIKER and CHAIN_ID are empty
if [ -z "$MONIKER" ] || [ -z "$CHAIN_ID" ]; then
    echo "MONIKER and/or CHAIN_ID is empty"
    exit 1
fi

# Check if SEED_URL and GAS_FEE are empty
if [ -z "$SEED_URL" ] || [ -z "$GAS_FEE" ]; then
    echo "SEED_URL and/or GAS_FEE is empty"
    exit 1
fi

# Check if REPO_HOME, DAEMON_NAME and DAEMON_HOME are empty
if [ -z "$REPO_HOME" ] || [ -z "$DAEMON_HOME" ] || [ -z "$DAEMON_NAME" ]; then
    echo "REPO_HOME and/or DAEMON_HOME  and/or DAEMON_NAME is empty"
    exit 1
fi

# Check if APP_VERSION and COSMOVISOR_VERSION are empty
if [ -z "$APP_VERSION" ] || [ -z "$COSMOVISOR_VERSION" ]; then
    echo "APP_VERSION and/or COSMOVISOR_VERSION is empty"
    exit 1
fi

# Check if GENESIS_URL is empty
if [ -z "$GENESIS_URL" ]; then
    echo "GENESIS_URL is empty"
    exit 1
fi

rm -rf $REPO_HOME
rm -rf $DAEMON_HOME
rm -rf /usr/local/bin/$DAEMON_NAME

cd /root
git clone $GITHUB_URL
cd $REPO_HOME

git checkout $APP_VERSION && \
    make build && \
    mkdir -p $DAEMON_HOME/cosmovisor/genesis/bin && \
    mv build/$DAEMON_NAME $DAEMON_HOME/cosmovisor/genesis/bin/ && \
    rm -rf build && \
    ln -s $DAEMON_HOME/cosmovisor/genesis $DAEMON_HOME/cosmovisor/current && \
    ln -s $DAEMON_HOME/cosmovisor/current/bin/$DAEMON_NAME /usr/local/bin/$DAEMON_NAME


go install cosmossdk.io/tools/cosmovisor/cmd/cosmovisor@$COSMOVISOR_VERSION

$DAEMON_NAME init $MONIKER --chain-id $CHAIN_ID

curl -Ls $GENESIS_URL > $DAEMON_HOME/config/genesis.json

if [ -n "$ADDRESS_BOOK_URL" ]; then
curl -Ls $ADDRESS_BOOK_URL > $DAEMON_HOME/config/addrbook.json
fi

sed -i -e "s|^seeds *=.*|seeds = \"$SEED_URL\"|" $DAEMON_HOME/config/config.toml
sed -i -e "s|^minimum-gas-prices *=.*|minimum-gas-prices = \"$GAS_FEE\"|" $DAEMON_HOME/config/app.toml


# Configure pruning options if available, else use default values
if [ -n "$PRUNING_OPTION" ] && [ -n "$PRUNING_KEEP_RECENT" ] && [ -n "$PRUNING_KEEP_EVERY" ] && [ -n "$PRUNING_INTERVAL" ]; then
    sed -i \
      -e "s|^pruning *=.*|pruning = \"$PRUNING_OPTION\"|" \
      -e "s|^pruning-keep-recent *=.*|pruning-keep-recent = \"$PRUNING_KEEP_RECENT\"|" \
      -e "s|^pruning-keep-every *=.*|pruning-keep-every = \"$PRUNING_KEEP_EVERY\"|" \
      -e "s|^pruning-interval *=.*|pruning-interval = \"$PRUNING_INTERVAL\"|" \
      $DAEMON_HOME/config/app.toml
fi

# Configure app.toml and config.toml values if environment variables are set, else use default values
if [ -n "$API_ENABLE" ]; then
    sed -i -e "s|^enable *=.*|enable = $API_ENABLE|" $DAEMON_HOME/config/app.toml
fi

if [ -n "$API_SWAGGER_ENABLE" ]; then
    sed -i -e "s|^swagger *=.*|swagger = $API_SWAGGER_ENABLE|" $DAEMON_HOME/config/app.toml
fi

if [ -n "$API_CORS_ENABLE" ]; then
    sed -i -e "s|^enabled-unsafe-cors *=.*|enabled-unsafe-cors = $API_CORS_ENABLE|" $DAEMON_HOME/config/app.toml
fi

# change config.toml values
sed -i 's/prometheus = false/prometheus = true/g' /root/.hid-node/config/config.toml
sed -i -e 's|tcp://127.0.0.1:26657|tcp://0.0.0.0:26657|g' $DAEMON_HOME/config/config.toml
sed -i -e 's|allow_duplicate_ip = false|allow_duplicate_ip = true|g' $DAEMON_HOME/config/config.toml
sed -i -e 's|addr_book_strict = true|addr_book_strict = false|g' $DAEMON_HOME/config/config.toml
sed -i -e 's|cors_allowed_origins = \[\]|cors_allowed_origins = \[\"\*\"\]|g' $DAEMON_HOME/config/config.toml

if [ "$STATE_SYNC" = "true" ]; then
# Run unsafe-reset-all to reset the node to a previous height
LATEST_HEIGHT=$(curl -s $STATE_SYNC_RPC/block | jq -r .result.block.header.height)
SYNC_BLOCK_HEIGHT=$(($LATEST_HEIGHT - $STATE_SYNC_MAX_VALID_HEIGHT))
SYNC_BLOCK_HASH=$(curl -s "$STATE_SYNC_RPC/block?height=$SYNC_BLOCK_HEIGHT" | jq -r .result.block_id.hash)
$DAEMON_NAME tendermint unsafe-reset-all --home $DAEMON_HOME
# Configure state sync parameters in config.toml
sed -i \
  -e "s|^enable *=.*|enable = true|" \
  -e "s|^rpc_servers *=.*|rpc_servers = \"$STATE_SYNC_RPC,$STATE_SYNC_RPC\"|" \
  -e "s|^trust_height *=.*|trust_height = $SYNC_BLOCK_HEIGHT|" \
  -e "s|^trust_hash *=.*|trust_hash = \"$SYNC_BLOCK_HASH\"|" \
  -e "s|^persistent_peers *=.*|persistent_peers = \"$STATE_SYNC_PEER\"|" \
  $DAEMON_HOME/config/config.toml
fi

if [ -n "$IMPORT_VALIDATOR" ]; then
# Check if VAL_KEY, VAL_PRIV_KEY and VAL_MNEMONIC are empty
if [ -z "$VAL_KEY" ] || [ -z "$VAL_MNEMONIC" ] || [ -z "$VAL_PRIV_KEY" ]; then
    echo "VAL_KEY, VAL_MNEMONIC and/or VAL_PRIV_KEY is empty"
    exit 1
fi
yes $VAL_MNEMONIC | $DAEMON_NAME keys add $VAL_KEY --recover --keyring-backend=$KEYRING_BACKEND --home=$DAEMON_HOME
echo "$VAL_PRIV_KEY" | jq '.' > "$DAEMON_HOME/config/priv_validator_key.json"
fi

# start the chain
cosmovisor run start

