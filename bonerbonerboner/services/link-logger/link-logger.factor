! Copyright (C) 2020 .
! See http://factorcode.org/license.txt for BSD license.

USING: kernel sequences http http.server.dispatchers accessors vocabs.parser furnace.actions regexp db.types db.tuples math urls strings calendar ;
USING: bonerbonerboner ;

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
    [ <link> insert-tuple ] with-bbb-db ;

: update-repost ( link who -- )
     [ <repost> update-tuple ] with-bbb-db ;

: repost? ( url -- link/f )
    link new swap >>url [ select-tuple ] with-bbb-db ;

: url-regex ( -- regexp )
    R/ http[s]?:\/\/(?:[a-zA-Z]|[0-9]|[$-_@.&+]|[!*\(\),]|(?:%[0-9a-fA-F][0-9a-fA-F]))+/i ;

: strip-urls ( str -- seq )
    url-regex all-matching-subseqs ;

: check-repost ( url who -- )
    [ dup repost? ] dip swap [  update-repost ] [ add-link ] if ;

! : check-links ( str -- )
 !   strip-urls [ check-repost ] each ;
