USING: kernel xml.syntax xml.traversal accessors words sequences calendar calendar.parser combinators io.streams.string assocs xml unicode arrays splitting html.components math.parser ;
USING: musicbrainz.entities ;

USING: prettyprint ;
IN: musicbrainz.parser

XML-NS: mb http://musicbrainz.org/ns/mmd-2.0#

ERROR: invalid-timestamp ;

: string>word ( str -- word )
    "musicbrainz.entities" lookup-word ;

: string>timestamp ( str -- timestamp )
    [ length ] keep
    [
        {
            { 4 [ read-0000 1 1 <date-gmt> ] }
            { 7 [ read-0000 "-" expect read-00 1 <date-gmt> ] }
            { 10 [ read-ymd <date-gmt> ] }
            [ drop invalid-timestamp ]
        } case
    ] with-string-reader ;

TAGS: mb-entity ( tag -- entity )
TAGS: entity-property ( entity tag -- entity )

TAG: name entity-property
    children>string >>name ;

TAG: sort-name entity-property
    children>string >>sort-name ;

TAG: disambiguation entity-property
    children>string >>disambiguation ;

TAG: country entity-property
    children>string >>country ;

TAG: packaging entity-property
    children>string >>packaging ;

TAG: gender entity-property
    children>string >lower string>word >>gender ;

TAG: iso-3166-2-code-list entity-property
    children-tags [ children>string ] map >array >>iso-codes ;

TAG: iso-3166-1-code-list entity-property
    children-tags [ children>string ] map >array >>iso-codes ;

TAG: isni-list entity-property
    children-tags [ children>string ] map >array >>isnis ;

TAG: begin entity-property
    children>string string>timestamp >>begin ;
TAG: end entity-property
    children>string string>timestamp >>end ;

TAG: title entity-property
    children>string >>title ;
TAG: language entity-property
    children>string >>language ;
TAG: script entity-property
    children>string >>script ;

TAG: status entity-property
    children>string string>word >>status ;
TAG: quality entity-property
    children>string string>word >>quality ;
TAG: text-representation entity-property
    children-tags text-representation new [ entity-property ] reduce
    >>text-representation ;
TAG: barcode entity-property
    children>string >>barcode ;

TAG: artwork entity-property
    children>string string>boolean >>artwork? ;
TAG: count entity-property
    children>string string>number >>count ;
TAG: front entity-property
    children>string string>boolean >>front? ;
TAG: back entity-property
    children>string string>boolean >>back? ;
TAG: cover-art-archive entity-property
    children-tags cover-art-archive new [ entity-property ] reduce
    >>cover-art-archive ;

TAG: release-event-list entity-property
    children-tags [ mb-entity ] map >array >>release-events ;

TAG: date entity-property
    children>string string>timestamp >>date ;

TAG: life-span entity-property
    children-tags life-span new [ entity-property ] reduce
    >>life-span ;

TAG: ended entity-property
    children>string string>boolean >>ended? ;

TAG: position entity-property
    children>string string>number >>position ;
TAG: length entity-property
    children>string string>number >>length ;
TAG: number entity-property
    children>string string>number >>number ;
TAG: format entity-property
    children>string >>format ;
TAG: editor entity-property
    children>string >>editor ;

TAG: track mb-entity
    [ children-tags track new [ entity-property ] reduce ]
    [ attrs>> "id" of ] bi 
    >>mbid ;

! TODO: turn this into an mb-entity
TAG: alias-list entity-property
    children-tags
    [
        [ children>string ]
        [
            attrs>>
            [ "sort-name" of ]
            [ "type" of >lower " " split "-" join string>word ]
            [ "locale" of ] tri
        ] bi
        alias boa
    ] map >array >>aliases ;

TAG: area entity-property
    [ children-tags area new [ entity-property ] reduce ]
    [ attrs>> [ "id" of ] [ "type" of string>word ] bi ] bi
    [ >>mbid ] dip >>type >>area ;

TAG: begin-area entity-property
    [ children-tags area new [ entity-property ] reduce ]
    [ attrs>> [ "id" of ] [ "type" of string>word ] bi ] bi
    [ >>mbid ] dip >>type >>begin-area ;

TAG: release-list mb-entity
    children-tags [ mb-entity ] map >array ;
TAG: release-list entity-property
    children-tags [ mb-entity ] map >array >>releases ;

TAG: asin entity-property
    children>string >>asin ;

TAG: artist mb-entity
    [ children-tags artist new [ entity-property ] reduce ]
    [ attrs>> [ "id" of ] [ "type" of string>word ] bi ] bi
    [ >>mbid ] dip >>type ;

TAG: release-event mb-entity
    children-tags release-event new [ entity-property ] reduce ;

TAG: release mb-entity
    [ children-tags release new [ entity-property ] reduce ]
    [ attrs>> "id" of ] bi >>mbid ;

TAG: collection mb-entity
    [ children-tags collection new [ entity-property ] reduce ]
    [ attrs>> "id" of  ] bi >>mbid ;

TAG: collection-list mb-entity
    children-tags [ mb-entity ] map >array ;

TAG: medium-list entity-property
    children-tags [ mb-entity ] map >array >>mediums ;

TAG: track-list entity-property
    children-tags [ mb-entity ] map >array >>tracks ;

TAG: medium mb-entity
    children-tags medium new [ entity-property ] reduce ;

TAG: artist-credit entity-property
    "artist" deep-tag-named mb-entity >>artist ;

TAG: label-info-list entity-property
    children-tags [ mb-entity ] map >array >>label-info ;

TAG: label-info mb-entity
    first-child-tag
    [ children-tags label new [ entity-property ] reduce ]
    [ attrs>> [ "id" of ] [ "type" of ] bi ] bi
    [ >>mbid ] dip >>type ;

TAG: recording entity-property
    [ children-tags recording new [ entity-property ] reduce ]
    [ attrs>> "id" of ] bi >>mbid >>recording ;

: parse-mb-response ( str -- entity )
    string>xml first-child-tag mb-entity ;
