! Copyright (C) 2020 .
! See http://factorcode.org/license.txt for BSD license.

USING: kernel fry db db.sqlite environment math.parser ;

IN: bonerbonerboner.services

CONSTANT: bbb-default-port 8069

: with-bbb-db ( quot -- )
    '[ "bbb.db" <sqlite-db> _ with-db ] call ; inline

: bbb-api-port ( -- port )
    "BBB_API_PORT" os-env [ string>number ] [ bbb-default-port ] if* ;
