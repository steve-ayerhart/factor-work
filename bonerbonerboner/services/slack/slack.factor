! Copyright (C) 2020 .
! See http://factorcode.org/license.txt for BSD license.

USING: io.sockets.secure kernel http http.server http.server.dispatchers accessors furnace.actions namespaces http.server.responses io.servers io.sockets.secure.debug json.reader assocs combinators sequences arrays threads locals formatting json.writer urls http.client hashtables ;
USING: prettyprint ;

IN: bonerbonerboner.services.slack

SYMBOLS: slack-callbacks current-slack-webhook-url current-slack-authorization-token ;

TUPLE: slack < dispatcher ;

: add-slack-handler ( quot: ( event -- ) -- )
    slack-callbacks get append slack-callbacks set ;

: <bad-callback-response> ( -- response )
    "400" "unrecognized event type" <trivial-response> ;

: <heartbeat-response> ( -- response )
    "slack" <text-content> ;

: <ok-response> ( -- response )
    "200" "OK" <trivial-response> ;

: handle-challenge ( json -- response )
    "challenge" of <text-content> ;

:: handle-slack-event ( slack-event -- response )
    "bot_id" slack-event key? "subtype" slack-event key? or
    [
        slack-callbacks get length slack-event <array>
        slack-callbacks get [ curry "Slack Callback" spawn drop ] 2each
    ] unless
    <ok-response> ;

: <slack-event-action> ( -- action )
    <action>
    [
        request get post-data>> data>> json> dup
        "type" of
        {
            { "url_verification" [ handle-challenge ] }
            { "event_callback" [ handle-slack-event ] }
            [ drop <bad-callback-response> ]
        } case
    ] >>submit ;

: <heartbeat-action> ( -- action )
    <action> [ <heartbeat-response> ] >>display ;

: slack-post-message ( payload -- )
    >json
    current-slack-webhook-url get >url
    <post-request>
    http-request 2drop ;

: say-slack ( str -- )
    "text" associate
    slack-post-message ;

: <slack> ( -- responder )
    slack new-dispatcher
    <slack-event-action> "slack-events" add-responder
    <heartbeat-action> "heartbeat" add-responder ;
