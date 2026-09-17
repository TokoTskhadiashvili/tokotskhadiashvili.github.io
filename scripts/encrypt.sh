#!/usr/bin/env bash
set -euo pipefail

if [ -z "${CONTENT_KEY:-}" ]; then
    echo "CONTENT_KEY not set. Run: export CONTENT_KEY=\$(openssl rand -hex 32)"
    exit 1
fi

if [ ${#CONTENT_KEY} -ne 64 ]; then
    echo "CONTENT_KEY must be 64 hex characters (32 bytes)"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$SCRIPT_DIR/../content-src/books"
OUT_DIR="$SCRIPT_DIR/../docs/books"

mkdir -p "$OUT_DIR"

for file in "$SRC_DIR"/*.json; do
    [ -e "$file" ] || continue

    name="$(basename "$file" .json)"
    out="$OUT_DIR/$name.enc"

    # 16-byte IV, prepended to the ciphertext so the app can read it back.
    iv="$(openssl rand -hex 16)"

    ciphertext="$(openssl enc -aes-256-cbc \
        -K "$CONTENT_KEY" \
        -iv "$iv" \
        -in "$file" \
        | base64)"

    # Concatenate raw IV bytes and ciphertext, then base64 the whole thing —
    # matching what DecryptBook expects.
    {
        echo -n "$iv" | xxd -r -p
        echo -n "$ciphertext" | base64 --decode
    } | base64 > "$out"

    echo "encrypted $name.json -> $name.enc"
done
