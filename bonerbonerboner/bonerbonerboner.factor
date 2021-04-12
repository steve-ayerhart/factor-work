! Copyright (C) 2020 .
! See http://factorcode.org/license.txt for BSD license.

USING: kernel http.server http.server.responses http.server.dispatchers furnace.actions html.forms accessors namespaces io.servers io.sockets.secure.debug sequences validators ;
USING: bonerbonerboner.services ;

USING: prettyprint ;
IN: bonerbonerboner

TUPLE: bbb < dispatcher ;

: bbb-themes ( -- themes )
    { "bbb" "rocket" "hockey" } ;

: v-valid-theme ( str -- theme )
    dup bbb-themes member? [ "not a valid theme" throw ] unless ;

: validate-theme ( -- )
    {
        { "theme" [ v-required v-valid-theme ] }
    } validate-params ;

: <theme-action> ( -- action )

    <page-action>

    [
        validate-theme
    ] >>init

    { bbb "templates/themes" } >>template ;

: <heartbeat-action> ( -- action )
    <action> [ "bonerbonerboner" <text-content> ] >>display ;

: <bbb> ( -- responder )
    bbb new-dispatcher
    <heartbeat-action> "heartbeat" add-responder
    <slack-event-action> "slack-events" add-responder
    <theme-action> "subdomain" add-responder ;

SYMBOL: current-bbb-server
: run-bbb-server ( -- )
    <bbb> main-responder set-global
    8080 httpd current-bbb-server set ;

: restart-bbb-server ( -- )
    current-bbb-server get stop-server
    run-bbb-server ;
