! Copyright (C) 2020 .
! See http://factorcode.org/license.txt for BSD license.
USING: kernel math math.parser strings calendar alien.syntax sequences urls http.client formatting json.reader assocs combinators splitting classes.maybe ;
USING: prettyprint ;

IN: nhl

TUPLE: conference
    { id integer }
    { name string }
    { short-name string }
    { abbreviation string } ;

TUPLE: timezone
    { id string }
    { offset integer }
    { tz string } ;

TUPLE: venue
    { name: string }
    { city: string }
    { timezone timezone } ;

TUPLE: division
    { id integer }
    { name string }
!    { name-short string }
    { abbreviation string }
    { conference maybe{ conference } } ;

TUPLE: franchise
    { id integer }
    { team-name string }
    { first-season-id integer }
    { location-name string }
    { most-recent-team-id integer } ;

TUPLE: team
    { id integer }
    { name string }
    { team-name string }
    { location-name string }
    { short-name string }
    { official-site-url url }
    { abbreviation string }
    ! { first-year timestamp }
    { first-year integer }
    { division division }
    { franchise franchise }
    { venue venue } ;

TUPLE: game-time
    { period integer }
    { period-sec integer } ;
! { period-sec timestamp } ;

TUPLE: location
    { x integer }
    { y integer } ;

TUPLE: player-position
    { code string }
    { name string }
    { type string }
    { abbreviation string } ;

TUPLE: player
    { id integer }
    { full-name string }
    { first-name string }
    { last-name string }
    { primary-number string }
    { current-team string }
    { position player-position }
    { height string }
    { weight integer }
    { shoots/catches string }
    { alternate-captain? boolean }
    { captain? boolean }
    { rookie? boolean }
    { nationality string }
    { birth-date timestamp }
    { birth-city string }
    { birth-state/prvince maybe{ string } }
    { birth-country string } ;

TUPLE: status
    { abstract-state string }
    { coded-state string }
    { detailed-state string }
    { code string }
    { start-time-tbd boolean } ;

TUPLE: league-record
    { wins integer }
    { losses integer }
    { ot integer }
    { type string } ;

TUPLE: team-info
    { scores integer }
    { attempts integer }
    { goals integer }
    { shots-on-goal integer }
    { rink-side string }
    { goalie-pulled? boolean }
    { num-skaters integer }
    { power-play? boolean }
    { league-record league-record }
    { score integer }
    { team team } ;

TUPLE: teams
    {  }

TUPLE: game
    { id integer }
    { link team }
    { type team }
    { season string }
    { date timestamp }
    { status status }
    { teams teams }
    { linescore linescore }
    { venue venue }
    { content content }
    { series-summary series-summary } ;

TUPLE: event
    { game-id integer }
    { id integer }
    { type string }
    { sub-type string }
    { time game-time }
    { location location }
    { team team }
    { by sequence }
    { on player } ;

TUPLE: date
    { date string }
    { total-items integer }
    { total-events integer }
    { total-games integer }
    { total-matches integer }
    { games sequence }
    { events sequence }
    { matches sequence } ;

TUPLE: schedule
    { copyright string }
    { total-items integer }
    { total-events integer }
    { total-games integer }
    { total-matches integer }
    { wait integer }
    { dates sequence } ;

CONSTANT: nhl-base-url "https://statsapi.web.nhl.com/api/v1/"
! TODO: CACHING

: >entity-url ( entity id -- url )
    dup string? [ string>number ] when
    "%s/%d" sprintf nhl-base-url prepend >url ;

: entity-get ( id entity -- json )
    swap over [
        >entity-url http-get nip json>
    ] dip of first ;

: entities-get ( entity -- seq )
    dup [
        nhl-base-url prepend http-get nip json>
    ] dip of ;

: parse-conference ( json -- conference )
    "CONF" . dup .
    {
        [ "id" of ] [ "name" of ] [ "shortName" of ] [ "abbreviation" of ]
    } cleave
    conference boa ;

: conference-get ( id -- conference ) "conferences" entity-get parse-conference ;
: conferences-get ( -- conferences ) "conferences" entities-get [ parse-conference ] map ;

: parse-division ( json -- division )
    {
        [ "id" of ] [ "name" of ] [ "abbreviation" of ]
!        [ "conference" of ] ! "id" of conference-get ]
    } cleave
    f
    division boa ;

: parse-franchise ( json -- franchise )
    {
        [ "franchiseId" of ] [ "teamName" of ] [ "firstSeasonId" of ]
        [ "locationName" of ] [ "mostRecentTeamId" of ]
    } cleave
    franchise boa ;

: parse-position ( json -- player-position )
    {
        [ "code" of ] [ "name" of ] [ "type" of ] [ "abbreviation" of ]
    } cleave player-position boa ;

: parse-player ( json -- player )
    {
        [ "id" of ]
        [ "fullName" of ]
        [ "firstName" of ]
        [ "lastName" of ]
        [ "primaryNumber" of ]
        [ "currentTeam" of "name" of ]
        [ "primaryPosition" of parse-position ]
        [ "height" of ]
        [ "weight" of ]
        [ "shootsCatches" of ]
        [ "alternateCaptain" of ]
        [ "captain" of ]
        [ "rookie" of ]
        [ "nationality" of ]
        [ "birthDate" of "-" split [ string>number ] map [ first ] [ second ] [ third ] tri <date> ]
        [ "birthCity" of ]
        [ "birthStateProvince" of ]
        [ "birthCountry" of ]
    } cleave player boa ;

: division-get ( id -- division )
    "divisions" entity-get parse-division ;
: divisions-get ( -- divisions )
    "divisions" entities-get [ parse-division ] map ;

: franchise-get ( id -- division )
    "franchises" entity-get parse-franchise ;
: franchises-get ( -- divisions )
    "franchises" entities-get [ parse-franchise ] map ;

: player-get ( id -- player ) "people" entity-get parse-player ;
: players-get ( ids -- players ) [ player-get ] map ;

: parse-timezone ( json -- timezone )
    [ "id" of ] [ "offset" of ] [ "tz" of ] tri timezone boa ;
: parse-venue ( json -- venue )
    [ "name" of ] [ "city" of ] [ "timeZone" of parse-timezone ] tri venue boa ;

: parse-team ( json -- team )
    {
        [ "id" of ] [ "name" of ] [ "teamName" of ] [ "locationName" of ]
        [ "shortName" of ] [ "officialSiteUrl" of >url ] [ "abbreviation" of ]
        [ "firstYearOfPlay" of string>number ] [ "division" of "id" of division-get ]
        [ "franchiseId" of franchise-get ] [ "venue" of parse-venue ]
    } cleave
    team boa ;

: team-get ( id -- team ) "teams" entity-get parse-team ;
: teams-get ( -- teams ) "teams" entities-get [ parse-team ] map ;
