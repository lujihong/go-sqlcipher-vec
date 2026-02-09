#!/bin/sh -e

# Build+sync SQLCipher sqlite3.c/sqlite3.h and needed tsrc headers.
#
# Usage:
#   ./sync_sqlcipher.sh <sqlcipher_root>
#
# Example:
#   ./sync_sqlcipher.sh /path/to/sqlcipher-4.13.0

if [ $# -ne 1 ]; then
  echo "Usage: $0 <sqlcipher_root>" >&2
  exit 1
fi

SQLCIPHER_ROOT="$1"

if [ ! -f "$SQLCIPHER_ROOT/configure" ]; then
  echo "ERROR: '$SQLCIPHER_ROOT/configure' not found." >&2
  exit 1
fi

# Always run relative to this script directory (repo root expected)
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
cd "$SCRIPT_DIR"

copy() {
  from="$1"
  to="$2"
  if [ ! -f "$from" ]; then
    echo "ERROR: missing source file: $from" >&2
    exit 1
  fi
  cp -f "$from" "$to"
}


echo "--- Building SQLCipher sqlite3.c ---"
(
  cd "$SQLCIPHER_ROOT"
  ./configure --with-tempstore=yes --disable-math \
    CFLAGS="-DSQLITE_CORE \
            -DSQLITE_HAS_CODEC \
            -DSQLITE_TEMP_STORE=2 \
            -DSQLCIPHER_CRYPTO_LIBTOMCRYPT \
            -DHAVE_STDINT_H \
            -DSQLCIPHER_CRYPTO_CUSTOM=sqlcipher_ltc_setup \
            -DSQLITE_EXTRA_INIT=sqlcipher_extra_init \
            -DSQLITE_EXTRA_SHUTDOWN=sqlcipher_extra_shutdown \
            -DSQLITE_ENABLE_FTS3 -DSQLITE_ENABLE_FTS3_PARENTHESIS \
            -DSQLITE_ENABLE_FTS4 -DSQLITE_ENABLE_FTS5 \
            -DSQLITE_ENABLE_RTREE -DSQLITE_ENABLE_GEOPOLY \
            -DSQLITE_ENABLE_JSON1 \
            -DSQLITE_ENABLE_SESSION -DSQLITE_ENABLE_PREUPDATE_HOOK \
            -DSQLITE_ENABLE_STAT4 \
            -DSQLITE_ENABLE_COLUMN_METADATA \
            -DSQLITE_ENABLE_DBSTAT_VTAB \
            -DSQLITE_ENABLE_UNLOCK_NOTIFY \
            -DSQLITE_ENABLE_STMTVTAB \
            -DSQLITE_ENABLE_FTS3_TOKENIZER" \
    LDFLAGS="-ltomcrypt -lm -lpthread"
  make sqlite3.c
)

echo "--- Syncing SQLCipher outputs ---"
copy "$SQLCIPHER_ROOT/sqlite3.c" "./sqlite3.c"
copy "$SQLCIPHER_ROOT/sqlite3.h" "./sqlite3.h"

echo "--- Syncing SQLCipher tsrc headers used by this repo ---"
TSRC="$SQLCIPHER_ROOT/tsrc"
copy "$TSRC/btree.h" "./btree.h"
copy "$TSRC/hash.h" "./hash.h"
copy "$TSRC/msvc.h" "./msvc.h"
copy "$TSRC/mutex.h" "./mutex.h"
copy "$TSRC/opcodes.h" "./opcodes.h"
copy "$TSRC/os_setup.h" "./os_setup.h"
copy "$TSRC/os.h" "./os.h"
copy "$TSRC/pager.h" "./pager.h"
copy "$TSRC/parse.h" "./parse.h"
copy "$TSRC/pcache.h" "./pcache.h"
copy "$TSRC/sqlcipher.h" "./sqlcipher.h"
copy "$TSRC/sqliteInt.h" "./sqliteInt.h"
copy "$TSRC/sqliteLimit.h" "./sqliteLimit.h"
copy "$TSRC/vdbe.h" "./vdbe.h"
copy "$TSRC/vxworks.h" "./vxworks.h"

echo "OK: synced SQLCipher sqlite3.c/sqlite3.h and tsrc headers from: $SQLCIPHER_ROOT"
