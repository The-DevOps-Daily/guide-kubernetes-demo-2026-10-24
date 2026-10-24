#!/usr/bin/env bash
# usage: scripts/run.sh NN   runs scripts/partNN.sh from the repository root
set -uo pipefail
cd "$(dirname "$0")/.."
# shellcheck source=scripts/lib.sh
source scripts/lib.sh
# shellcheck source=/dev/null
source "scripts/part$1.sh"
