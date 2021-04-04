! Copyright (C) 2020 .
! See http://factorcode.org/license.txt for BSD license.
USING: kernel math math.ranges math.order math.parser math.functions arrays sequences sequences.extras threads calendar io timers accessors random formatting combinators combinators.random http.server.responses ;
USING: prettyprint http furnace.actions http.server.dispatchers ;
USING: bonerbonerboner.services.slack ;

IN: bonerbonerboner.services.mississippis

CONSTANT: max-mississippi-count 30
CONSTANT: min-mississippi-count 1

: random-stupid-word ( -- something-stupid )
    { "balls" "fart" "SIEEEEEEEEEEGE" "hey" "HONESTLY" "fuckface" "it's too late-TOOOOO LATE" }
    random ;

: random-m-word ( -- m-word )
    { "Minnesota" "Montana" "Marsupial" "Minneapolis" }
    random ;

: random-no-word ( -- nope )
    { "No can doobie" "Can't do that" "I don't think so, kev" "nope" "Can't, learn the rules" }
    random ;

: nonstandard-mississippi-duration ( -- duration )
    .25 5 uniform-random-float seconds ;

: standard-mississippi-duration ( -- duration )
    1 seconds ;

: nonstandard-mississippi-wait ( -- )
    nonstandard-mississippi-duration sleep ;

: valid-mississippi-count? ( n -- ? )
    min-mississippi-count max-mississippi-count between? ;

: announce ( str -- )
    . flush ;
!    say-slack ;

: announce-sip ( sip -- )
    "%d Mississippi" sprintf announce ;

: announce-fake-terminal ( terminal -- )
    number>string random-m-word 2array " " join announce ;

: announce-random-stupid-word ( -- )
    random-stupid-word announce ;

: announce-random-sip ( -- )
    1000 random announce-sip ;

: announce-go! ( -- )
    "GO!" announce ;

: announce-standard-mississippis ( terminal -- )
    [1,b] [ standard-mississippi-duration sleep announce-sip ] each ;

:: announce-nonstandard-mississippi ( terminal sip -- )
    {
        { .3  [ ] }
        { .1  [ announce-random-sip ] }
        { .075 [ announce-random-stupid-word ] }
        { .025 [ terminal announce-fake-terminal ] }
        { .5  [ sip announce-sip ] }
    } casep ;

: announce-nonstandard-mississippis ( terminal -- )
    [
        1 - [ dup <array> ] [ [1,b] ] bi
        [ nonstandard-mississippi-wait announce-nonstandard-mississippi ] 2each
    ]
    [ announce-sip ] bi ;

: announce-mississippis ( terminal standard? -- )
    [ announce-standard-mississippis ] [ announce-nonstandard-mississippis ] if ;

: mississippi-go! ( standard? terminal -- )
    dup valid-mississippi-count?
    [ announce-go! swap announce-mississippis ]
    [ 2drop random-no-word announce ] if ;

: <heartbeat-response> ( -- response )
    "mississippis" <text-content> ;
