! Copyright (C) 2020 .
! See http://factorcode.org/license.txt for BSD license.
USING: kernel regexp sequences http.server http.server.responses db db.types db.tuples unicode formatting assocs ;
USING: bonerbonerboner.services bonerbonerboner.services.slack ;

IN: bonerbonerboner.services.platzisms

TUPLE: platzism id quote ;

platzism "platzisms"
{
    { "id" "id" +db-assigned-id+ }
    { "quote" "quote" TEXT }
} define-persistent

: ensure-platzisms ( -- )
    [ platzism ensure-table ] with-bbb-db ;

: <platzism> ( str -- platzism )
    [ f ] dip platzism boa ;

: add-platzism ( str -- )
    ensure-platzisms
    [ <platzism> insert-tuple ] with-bbb-db ;

: platzism-exists? ( str -- ? )
    [ >lower "SELECT id FROM platzisms WHERE lower(quote) = '%s'" sprintf sql-query ] with-bbb-db empty? not ;

: is-platz? ( str -- ? )
    R/ ^platz\?$/i matches? ;

: is-platzism? ( str -- ? )
    R/ ^steve platz is currently .+/i matches? ;

: random-platzism ( -- platzism )
    ensure-platzisms
    "SELECT quote from platzisms ORDER BY RANDOM() LIMIT 1" [ sql-query ] with-bbb-db
    dup empty? [ drop "I'm not sure what Platz is up to." ] [ first first ] if ;

: repost-callout ( -- )
    "We already know Platz is doing that" say-slack ;

: confirm-platzism ( -- )
    "noted" say-slack ;

: share-platzism ( -- )
    random-platzism say-slack  ;

: log/confirm-platzism ( str -- )
    dup platzism-exists?
    [ drop repost-callout ]
    [
        add-platzism
        confirm-platzism
    ] if ;

: check-platz ( event -- )
    "text" of
    [ is-platz? [ share-platzism ] when ]
    [ dup is-platzism? [ log/confirm-platzism ] [ drop ] if  ] bi ;

! [ check-platz ] add-slack-handler

