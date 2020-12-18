! Copyright (C) 2020 .
! See http://factorcode.org/license.txt for BSD license.
USING: kernel io.sockets.secure http http.client urls strings alien.syntax accessors arrays sequences xml.syntax xml.traversal assocs slots calendar words calendar.parser combinators io.streams.string furnace.utilities splitting qw hashtables ;
USING: io prettyprint ;
USING: musicbrainz.entities musicbrainz.parser ;
IN: musicbrainz

CONSTANT: mb-base-url URL" https://musicbrainz.org/ws/2/"
CONSTANT: user-agent-header { "factor-musicbrainz/0.1.0 (steve@ayerh.art)" "user-agent" }
CONSTANT: accept-header { "application/xml" "accept" }
CONSTANT: collection-links qw{ releases }

: mb-entity>string ( entity -- str )
    word>string ":" split last ;

: <mb-entity-url> ( mbid entity inc -- url )
    [
        word>string ":" split last swap 2array "/" join
        mb-base-url clone swap >url derive-url
    ] dip "+" join "inc" set-query-param ;

: <mb-release-url> ( mbid -- url )
    release qw{ artist-credits recordings labels aliases } <mb-entity-url> ;

: <mb-artist-url> ( mbid -- url )
    artist qw{ aliases } <mb-entity-url> ;

: <mb-collection-url> ( mbid -- url )
    "/releases" append collection qw{ artist-credits releases } <mb-entity-url> ;

: <mb-get-request> ( url -- request )
    <get-request>
    user-agent-header first2 set-header
    accept-header first2 set-header
    http-request nip parse-mb-response ;

: add-mb-headers ( url -- url )
    user-agent-header first2 set-header
    accept-header first2 set-header ;

: <mb-release-lookup> ( mbid -- release )
    <mb-release-url> <mb-get-request> ;

: <mb-artist-lookup> ( mbid -- artist )
    <mb-artist-url> <mb-get-request> ;

: <mb-collection-lookup> ( mbid -- collection )
    <mb-collection-url> <mb-get-request> ;

: <mb-collection-release-url> ( mbid -- url )
    [ mb-base-url clone "release" >url derive-url ] dip
    "collection" set-query-param 
    "100" "limit" set-query-param ;

: <mb-collection-release-request> ( mbid -- releases )
    <mb-collection-release-url> <mb-get-request> ;

: <mb-collections-lookup> ( user -- collections )
    [ mb-base-url clone "collection" >url derive-url ] dip
    "editor" set-query-param
    <get-request> add-mb-headers http-request nip parse-mb-response ;
