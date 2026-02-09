package sqlite3

/*
#cgo CFLAGS: -DSQLITE_CORE

// enable encryption codec in sqlite
#cgo CFLAGS: -DSQLITE_HAS_CODEC

// required by SQLCipher 4.7+ (see sqlcipher.c):
#cgo CFLAGS: -DSQLITE_EXTRA_INIT=sqlcipher_extra_init
#cgo CFLAGS: -DSQLITE_EXTRA_SHUTDOWN=sqlcipher_extra_shutdown

// use memory for temporay storage in sqlite
#cgo CFLAGS: -DSQLITE_TEMP_STORE=2

// use libtomcrypt implementation in sqlcipher
#cgo CFLAGS: -DSQLCIPHER_CRYPTO_LIBTOMCRYPT
#cgo CFLAGS: -DSQLCIPHER_CRYPTO_CUSTOM=sqlcipher_ltc_setup
#cgo CFLAGS: -DSQLCIPHER_TEST

// disable anything "not portable" in libtomcrypt
#cgo CFLAGS: -DLTC_NO_ASM

// disable assertions
#cgo CFLAGS: -DNDEBUG

// set operating specific sqlite flags
#cgo linux CFLAGS: -DSQLITE_OS_UNIX=1
#cgo windows CFLAGS: -DSQLITE_OS_WIN=1
*/
import "C"
