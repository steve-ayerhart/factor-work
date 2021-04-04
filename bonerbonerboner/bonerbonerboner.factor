! Copyright (C) 2020 .
! See http://factorcode.org/license.txt for BSD license.

USING: kernel http.server http.server.responses http.server.dispatchers furnace.actions html.forms accessors namespaces io.servers io.sockets.secure.debug ;
USING: bonerbonerboner.services ;

IN: bonerbonerboner

TUPLE: bbb < dispatcher ;

: <theme-action> ( -- action )

    <page-action> [ "bbb" "theme" set-value ] >>init

    { bbb "templates/themes" } >>template ;


: <heartbeat-response> ( -- response )
    "bonerbonerboner" <text-content> ;

: <bbb> ( -- responder )
    bbb new-dispatcher
    <heartbeat-response> "heartbeat" add-responder ;
!    <theme-action> "theme" add-responder ;

SYMBOL: current-test-server
: run-test-bbb ( -- )
    <bbb> main-responder set-global
    8080 httpd current-test-server set ;
