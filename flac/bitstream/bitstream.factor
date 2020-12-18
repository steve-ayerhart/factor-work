! Copyright (C) 2009 Daniel Ehrenberg
! See http://factorcode.org/license.txt for BSD license.
USING: kernel system destructors accessors byte-arrays math locals io.files io.encodings.binary combinators sequences namespaces ;
QUALIFIED: bitstreams
QUALIFIED: io
USING: prettyprint ;

IN: flac.bitstream

CONSTANT: default-bitreader-capacity 65536
SYMBOL: flac-input-stream

TUPLE: flac-stream-reader stream bitstream ;

GENERIC: read-uint ( n flac-stream-reader -- n )
GENERIC: align-to-byte ( flac-stream-reader -- )

: <flac-stream-reader> ( path -- flac-stream-reader )
    binary <file-reader> B{ } bitstreams:<msb0-bit-reader> flac-stream-reader boa ;

M: flac-stream-reader dispose stream>> dispose ;

: flac-align-to-byte ( -- )
    8 flac-input-stream get bitstream>> bitstreams:align ;

: flac-read-uint ( n -- n )
    [ dup flac-input-stream get bitstream>> bitstreams:enough-bits? not ]
    [
        flac-input-stream get
        [ stream>> default-bitreader-capacity swap io:stream-read ] [ bitstream>> ] bi
        dup bytes>> swap [ prepend ] dip swap >>bytes drop
    ] while flac-input-stream get bitstream>> bitstreams:read ;

: flac-read-sint ( n -- n )
    ! TODO: this isn't rightt
    dup flac-read-uint dup . dup 1 - neg shift swap shift ;

: with-flac-stream-reader* ( flac-bitstream quot -- )
    flac-input-stream swap with-variable ; inline

: with-flac-stream-reader ( flac-bitstream quot -- )
    [ with-flac-stream-reader* ] curry with-disposal ; inline

: with-flac-file-reader ( filename quot -- )
    [ <flac-stream-reader> ] dip with-flac-stream-reader ; inline
