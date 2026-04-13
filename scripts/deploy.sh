#! /bin/sh

set -e

export MIX_ENV=prod
export MIX_TARGET=rpi4
export HOST=darker.local

MIX_TARGET=host mix do deps.get + assets.deploy
mix deps.get
mix firmware
mix upload $HOST
