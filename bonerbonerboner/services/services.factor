! Copyright (C) 2020 .
! See http://factorcode.org/license.txt for BSD license.

USING: kernel fry db db.sqlite environment math.parser io.pathnames ;
USING: bonerbonerboner.services.slack ;

IN: bonerbonerboner.services

CONSTANT: bbb-default-port 8069

: bbb-data-directory ( -- path )
    home ".bonerbonerboner" append-path ;

: <bbb-sqlite-db> ( -- db )
    bbb-data-directory "bbb.db" append-path <sqlite-db> ;

: with-bbb-db ( quot -- )
    '[ <bbb-sqlite-db> _ with-db ] call ; inline

: bbb-api-port ( -- port )
    "BBB_API_PORT" os-env [ string>number ] [ bbb-default-port ] if* ;
