! Copyright (C) 2020 .
! See http://factorcode.org/license.txt for BSD license.

USING: io.sockets.secure kernel http http.server http.server.dispatchers accessors furnace.actions namespaces http.server.responses io.servers io.sockets.secure.debug json.reader assocs combinators sequences arrays threads locals formatting json.writer urls http.client hashtables math ;
USING: prettyprint io.encodings.utf8 io io.files ;

IN: bonerbonerboner.services.slack

SYMBOLS: slack-callbacks current-slack-webhook-url current-slack-authorization-token ;

TUPLE: slack < dispatcher ;

: <bad-callback-response> ( -- response )
    "400" "unrecognized event type" <trivial-response> ;

: <heartbeat-response> ( -- response )
    "slack" <text-content> ;

: handle-challenge ( json -- response )
    "challenge" of <text-content> ;

:: handle-slack-event ( slack-event -- response )
    "bot_id" slack-event key? "subtype" slack-event key? or
    [
        slack-callbacks get length slack-event <array>
        slack-callbacks get [ curry "Slack Callback" spawn drop ] 2each
    ] unless
    <200> ;

: <slack-event-action> ( -- action )
    <action>
    [
        request get post-data>> data>> json> dup
        "type" of
        {
            { "url_verification" [ handle-challenge ] }
            { "event_callback" [ "event" of handle-slack-event ] }
            [ drop <bad-callback-response> ]
        } case
    ] >>submit ;

: slack-lookup-user ( id -- name )
    [
        "https://slack.com/api/users.profile.get" >url
        { "user" "token" }
    ] dip
    current-slack-authorization-token get 2array zip
    set-query-params
    http-get swap drop json>
    "profile" of "real_name" of ;

: slack-post-message ( payload -- )
    >json
    current-slack-webhook-url get >url
    <post-request>
    http-request 2drop ;

: say-slack ( str -- )
    . flush ;
!    "text" associate
!    slack-post-message ;
