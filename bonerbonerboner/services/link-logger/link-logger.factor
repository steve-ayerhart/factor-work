! Copyright (C) 2020 .
! See http://factorcode.org/license.txt for BSD license.

USING: kernel sequences http http.server.dispatchers accessors vocabs.parser furnace.actions regexp db.types db.tuples math urls strings calendar assocs arrays formatting combinators.random ;
USING: bonerbonerboner.services bonerbonerboner.services.slack ;

IN: bonerbonerboner.services.link-logger

! TODO: index url and updated date
! TODO: add slack integration

TUPLE: link id url created-by updated-by repost-count date-created date-updated ;

link "links"
{
    { "id" "id" +db-assigned-id+ }
    { "url" "url" URL }
    { "repost-count" "repost_count" INTEGER }
    { "created-by" "created_by" TEXT }
    { "updated-by" "updated_by" TEXT }
    { "date-created" "date_created" TIMESTAMP }
    { "date-updated" "date_updated" TIMESTAMP }
} define-persistent

: ensure-link-logger ( -- )
    [ link ensure-table ] with-bbb-db ;

: <link> ( url who -- link )
    [ f ] 2dip dup 0 now dup link boa ;

: <repost> ( link who -- link )
    [ dup repost-count>> 1 + >>repost-count ] dip >>updated-by now >>date-updated ;

: add-link ( url who -- )
    ensure-link-logger [ <link> insert-tuple ] with-bbb-db ;

: random-callout ( repost -- )
    {
        [ ]
        [ created-by>> "%s already posted that" sprintf ]
        [ drop "nice repost" ]
    } call-random say-slack ;

: update-repost ( link who -- )
    ensure-link-logger [ <repost> dup update-tuple ] with-bbb-db random-callout ;

: repost? ( url -- link/f )
    link new swap >>url [ select-tuple ] with-bbb-db ;

: url-regex ( -- regexp )
    R/ http[s]?:\/\/(?:[a-zA-Z]|[0-9]|[$-_@.&+]|[!*\(\),]|(?:%[0-9a-fA-F][0-9a-fA-F]))+/i ;

: strip-urls ( str -- seq )
    url-regex all-matching-subseqs ;

: check-repost ( url who -- )
    [ dup repost? ] dip swap [  swap update-repost drop ] [ add-link ] if* ;

: check-link ( url who -- )
    check-repost ;

: check-links ( event -- )
    [ "text" of strip-urls dup length ] [ "user" of ] bi <array>
    [ check-link ] 2each ;
