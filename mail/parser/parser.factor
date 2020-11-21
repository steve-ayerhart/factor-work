USING: kernel peg.parsers sequences sequences.parser make strings qw sequences.deep calendar calendar.english calendar.parser math math.parser math.order accessors combinators peg unicode parser arrays combinators.short-circuit splitting assocs vocabs.parser words slots.syntax quotations regexp documents.private ;
USING: prettyprint ;

IN: mail.parser

TUPLE: mailbox-field display-name local domain ;

TUPLE: received-field tokens date-time ;

TUPLE: content-type sub-type parameters ;

TUPLE: content-type/text < content-type ;
TUPLE: content-type/image < content-type ;
TUPLE: content-type/video < content-type ;
TUPLE: content-type/audio < content-type ;
TUPLE: content-type/application < content-type ;
TUPLE: content-type/multipart < content-type ;
TUPLE: content-type/unknown < content-type ;

TUPLE: mail-header
    mime-version content-type
    bcc cc comments date from in-reply-to keywords
    message-id references reply-to sender subject to
    { optional-fields initial: { } } ;

TUPLE: multipart-header
    content-type content-transfer-encoding content-id content-disposition ;

TUPLE: multipart header message ;

TUPLE: mail { header mail-header } body ;

! Core rules

: wsp-parser ( -- parser )
    " " token "\t" token 2choice ;

: crlf-parser ( -- parser )
    "\r\n" token hide ;

: special? ( ch -- ? )
    "()<>[]:;@\\,.\"" member? ;

: except ( quot -- parser )
    [ not ] compose satisfy [ 1string ] action ; inline

: except-these ( quots -- parser )
    [ 1|| ] curry except ; inline

: digit-parser ( -- parser )
    "0-9" range-pattern [ 1string ] action ;

: digit-parser2 ( -- parser )
    digit-parser 2 exactly-n ;

: digit-parser4 ( -- parser )
    digit-parser 4 exactly-n ;

: vchar-parser ( -- parser )
    CHAR: \x20 CHAR: \x7e range [ 1string ] action ;

: quoted-pair ( -- parser )
    CHAR: \ 1token vchar-parser wsp-parser 2choice 2seq ;

! Folding White Space and Comments

: ctext-parser ( -- parser )
    { [ control? ] [ "()" member? ] } except-these ;

: foldable-wsp-parser ( -- parser )
    wsp-parser repeat0 crlf-parser 2seq optional
    wsp-parser repeat1 2seq ;

: comment-parser ( -- parser )
    ctext-parser [ comment-parser ] delay 2choice repeat0 "(" ")" surrounded-by hide ;

: comment-foldable-wsp-parser ( -- parser )
    foldable-wsp-parser optional
    comment-parser 2seq repeat1 foldable-wsp-parser optional 2seq
    foldable-wsp-parser 2choice ;

! Atom

: atext-parser ( -- parser )
    "a-zA-Z0-9!#$%&'*+-/=?^_`{}|~" range-pattern [ 1string ] action ;

: atom-parser ( -- parser )
    comment-foldable-wsp-parser optional hide
    atext-parser repeat1
    comment-foldable-wsp-parser optional hide 3seq [ flatten "" concat-as ] action ;

: dot-atom-parser ( -- parser )
    atom-parser "." token atom-parser 2seq repeat0 optional 2seq sp [ flatten "" concat-as ] action ;

! Quoted Strings

: quoted-string-parser ( -- parser )
    string-parser ;

! Miscellaneous Tokens

: word-parser ( -- parser )
    atom-parser quoted-string-parser 2choice ;

: phrase-parser ( -- parser )
    word-parser repeat1 [ "" concat-as ] action ;

: unstructured-parser ( -- parser )
    foldable-wsp-parser optional vchar-parser 2seq repeat0 wsp-parser repeat0 2seq
    [ flatten "" concat-as ] action sp ;

! Date and Time Specification

: date-time-zone-parser ( -- parser )
    foldable-wsp-parser hide "+" token "-" token 2choice digit-parser4 3seq
    [ flatten "" concat-as parse-rfc822-gmt-offset ] action ;

: date-time-second-parser ( -- parser )
    digit-parser2 [ "" concat-as string>number ] action
    [ 0 60 between? ] semantic ;

: date-time-hour-parser ( -- parser )
    digit-parser2 [ "" concat-as string>number ] action
    [ 0 23 between? ] semantic ;

: date-time-minute-parser ( -- parser )
    digit-parser2 [ "" concat-as string>number ] action
    [ 0 59 between? ] semantic ;

: time-of-day-parser ( -- parser )
    date-time-hour-parser ":" token hide
    date-time-minute-parser ":" token hide
    date-time-second-parser 2seq optional
    [ [ first ] [ 0 ] if* ] action
    4seq ;

: date-time-time-parser ( -- parser )
    time-of-day-parser date-time-zone-parser 2seq ;

: date-time-year-parser ( -- parser )
    foldable-wsp-parser hide
    digit-parser 4 at-least-n
    foldable-wsp-parser hide 3seq
    [ flatten "" concat-as string>number ] action
    [ 1900 >= ] semantic ;

: date-time-month-parser ( -- parse )
    qw{ Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec } [ token ] map choice
    [ month-abbreviations index 1 + ] action ;

: date-time-day-parser ( -- parser )
    foldable-wsp-parser optional hide
    digit-parser 1 2 from-m-to-n
    foldable-wsp-parser hide 3seq
    [ flatten "" concat-as string>number ] action ;

: date-time-date-parser ( -- parser )
    date-time-day-parser
    date-time-month-parser
    date-time-year-parser 3seq ;

: date-time-day-name-parser ( -- parser )
    qw{ Mon Tue Wed Thu Fri Sat Sun } [ token ] map choice ;

: date-time-day-of-week-parser ( -- parser )
    foldable-wsp-parser optional
    date-time-day-name-parser 2seq ;

: date-time-parser ( -- parser )
    date-time-day-of-week-parser "," token 2seq optional hide
    date-time-date-parser
    date-time-time-parser
    comment-foldable-wsp-parser optional hide 4seq
    [
        flatten
        [ timestamp new ] dip
        [ ] each
        {
            [ >>day ] [ >>month ] [ >>year ]
            [ >>hour ] [ >>minute ] [ >>second ]
            [ >>gmt-offset ]
        } spread
    ] action ;

! Addr-Spec Specification

: dtext-parser ( -- parser )
    { [ " []\\" member? ] [ control? ] } except-these repeat0 ;

: domain-literal-parser ( -- parser )
    [
        comment-foldable-wsp-parser optional ,
        foldable-wsp-parser optional
        dtext-parser 2seq
        foldable-wsp-parser optional 2seq
        "[" "]" surrounded-by ,
        comment-foldable-wsp-parser optional ,
    ] seq* [ flatten "" concat-as ] action ;

: domain-parser ( -- parser )
    dot-atom-parser domain-literal-parser 2choice ;

: local-part-parser ( -- parser )
    dot-atom-parser quoted-string-parser 2choice ;

: addr-spec-parser ( -- parser )
    local-part-parser "@" token hide domain-parser 3seq
    [ f swap [ ] each mailbox-field boa ] action ;

! Address Specification

: display-name-parser ( -- parser )
    phrase-parser ;

: angle-addr ( -- parser )
    comment-foldable-wsp-parser optional hide
    addr-spec-parser "<" ">" surrounded-by
    comment-foldable-wsp-parser optional hide 3seq [ first ] action ;

: name-addr-parser ( -- parser )
    display-name-parser optional angle-addr 2seq [ [ ] each swap >>display-name ] action ;

: mailbox-parser ( -- parser )
    name-addr-parser addr-spec-parser 2choice ;

: mailbox-list-parser ( -- parser )
    mailbox-parser "," token list-of [ >array ] action ;

DEFER: group-parser

: address-parser ( -- parser )
    mailbox-parser group-parser 2choice [ ] action ;

: group-list-parser ( -- parser )
    mailbox-list-parser comment-foldable-wsp-parser 2choice ;

: group-parser ( -- parser )
    [
        display-name-parser ,
        ":" token ,
        group-list-parser optional ,
        ";" token ,
        comment-foldable-wsp-parser optional hide ,
    ] seq* ;

: address-list-parser ( -- parser )
    address-parser "," token list-of [ >array ] action ;

! Optional Fields

: ftext ( -- parser )
    CHAR: \x21 CHAR: \x39 range
    CHAR: \x3b CHAR: \x7e range
    2choice [ 1string ] action ;

: known-field-name-parser ( str -- parser )
    [ ftext repeat1 [ "" concat-as >lower ] action ] dip [ = ] curry semantic ;

: field-name-parser ( -- parser )
    ftext repeat1 [ "" concat-as >lower ] action ;

: field-parser ( -- parser )
    [
        field-name-parser ,
        ":" token ,
        unstructured-parser ,
        crlf-parser ,
    ] seq* ;

: known-field-parser ( str parser -- parser )
    [
        known-field-name-parser
        ":" token hide
    ] dip
    crlf-parser 4seq [ >array ] action ;

: no-fold-literal ( -- parser )
    dtext-parser repeat0 "[" "]" surrounded-by ;

: id-left-parser ( -- parser )
    dot-atom-parser ;

: id-right-parser ( -- parser )
    dot-atom-parser no-fold-literal 2choice ;

: msg-id-parser ( -- parser )
    comment-foldable-wsp-parser optional hide
    id-left-parser "@" token id-right-parser 3seq [ "" concat-as ] action
    "<" ">" surrounded-by
    comment-foldable-wsp-parser optional hide 3seq [ first ] action ;

! The origination Date Field

: orig-date-parser ( -- parser )
    "date" date-time-parser known-field-parser ;

! Originator fields

: from-parser ( -- parser )
    "from" mailbox-list-parser known-field-parser ;
: sender-parser ( -- parser )
    "sender" mailbox-parser known-field-parser ;
: reply-to-parser ( -- parser )
    "reply-to" address-list-parser known-field-parser ;

! Destination Address fields

: to-parser ( -- parser )
    "to" address-list-parser known-field-parser ;
: cc-parser ( -- parser )
    "cc" address-list-parser known-field-parser ;
: bcc-parser ( -- parser )
    "bcc" address-list-parser known-field-parser ;

: message-id-parser ( -- parser )
    "message-id" msg-id-parser known-field-parser ;

: in-reply-to-parser ( -- parser )
    "in-reply-to" msg-id-parser repeat1 [ >array ] action known-field-parser ;

: references-parser ( -- parser )
    "references" msg-id-parser repeat1 [ >array ] action known-field-parser ;

: subject-parser ( -- parser )
    "subject" unstructured-parser known-field-parser ;

: comments-parser ( -- parser )
    "comments" unstructured-parser known-field-parser ;

: keywords-parser ( -- parser )
    "keywords" phrase-parser sp "," token list-of [ >array ] action known-field-parser ;

! Resent Fields

: resent-date-parser ( -- parser )
    "resent-date" date-time-parser known-field-parser ;

: resent-from-parser ( -- parser )
    "resent-from" mailbox-list-parser known-field-parser ;

: resent-sender-parser ( -- parser )
    "resent-sender" mailbox-parser known-field-parser ;

: resent-to-parser ( -- parser )
    "resent-to" address-list-parser known-field-parser ;

: resent-cc-parser ( -- parser )
    "resent-cc" address-list-parser known-field-parser ;

: resent-bcc-parser ( -- parser )
    "resent-bcc" address-list-parser known-field-parser ;

: resent-message-id-parser ( -- parser )
    "resent-message-id" msg-id-parser known-field-parser ;

! Trace Fields

: received-token-parser ( -- parser )
    angle-addr addr-spec-parser domain-parser word-parser 4choice ;

: path-parser ( -- parser )
    angle-addr comment-foldable-wsp-parser "<" ">" surrounded-by 2choice ;

: return-path-parser ( -- parser )
    "return-path" path-parser known-field-parser ;

: received-parser ( -- parser )
    "received"
    received-token-parser repeat0 [ >array ] action
    ";" token hide
    date-time-parser 3seq
    [ [ ] each received-field boa ] action
    known-field-parser ;

: trace-parser ( -- parser )
    return-path-parser optional
    received-parser repeat1 2seq [ flatten >array ] action ;

! Content-Type Field

: trim-quotes ( str -- str' )
    [ CHAR: \" = ] trim ;
: trim-blanks ( str -- str' )
    [ blank? ] trim ;

: parse-content-type ( str -- mime-type )
    [
        [ "/" take-until-sequence* >lower ]
        [ ";" take-until-sequence* >lower ]
        [ take-rest ";" split [ "=" split1 [ trim-blanks trim-quotes ] bi@ ] H{ } map>assoc ] tri rot
    ] parse-sequence >lower
    {
        { "text" [ content-type/text boa ] }
        { "image" [ content-type/image boa ] }
        { "audio" [ content-type/audio boa ] }
        { "video" [ content-type/video boa ] }
        { "application" [ content-type/application boa ] }
        { "multipart" [ content-type/multipart boa ] }
        { "unknown" [ content-type/unknown boa ] }
        [ drop content-type/unknown boa ]
    } case ;

: content-type-parser ( -- parser )
    "content-type" unstructured-parser [ parse-content-type ] action known-field-parser ;

: parse-content-disposition ( str -- content-disposition )
    ";" split [ "=" split1 [ trim-blanks trim-quotes ] bi@ ] H{ } map>assoc ;

: optional-field-parser ( -- parser )
    field-name-parser ":" token hide unstructured-parser crlf-parser 4seq [ >array ] action ;

: known-multipart-field-parser ( str parser -- parser )
        [
            known-field-name-parser
            ":" token hide
        ] dip
        3seq [ >array ] action ;

: multipart-header-field-parser ( -- parser )
    "content-type" unstructured-parser [ parse-content-type ] action known-multipart-field-parser
    "content-disposition" unstructured-parser [ parse-content-disposition ] action known-multipart-field-parser
    "content-id" unstructured-parser known-multipart-field-parser
    "content-transfer-encoding" unstructured-parser known-multipart-field-parser
    4choice ;

PEG: parse-multipart-field-header ( str -- header ) multipart-header-field-parser ;

: parse-multipart-beginning ( str boundary -- str' )
    [ <sequence-parser> ] dip
    [ take-sequence drop ] curry
    [ take-rest ] bi ;

: parse-multipart-header ( str -- header str' )
    [
        [
            "\r\n\r\n" take-until-sequence*
            [
                string-lines
                multipart-header new
                [
                    parse-multipart-field-header
                    [ second ] [ first ] bi >>writer-word
                    1quotation call( multipart-header value -- multipart-header )
                ] reduce
            ]
            [ f ] if*
        ]
        [ take-rest ] bi
    ] parse-sequence ;


: parse-multipart ( str separator -- seq )
    "--" prepend "-?-?\r\n" append dup <regexp> [ parse-multipart-beginning ] dip re-split
    [
        [ from>> ] [ to>> ] [ seq>> ] tri subseq
        parse-multipart-header [ multipart boa ] when*
    ] map sift ;

: fields-parser ( -- seq )
    [
        trace-parser ,
        resent-date-parser ,
        resent-from-parser ,
        resent-sender-parser ,
        resent-to-parser ,
        resent-cc-parser ,
        resent-bcc-parser ,
        resent-message-id-parser ,
        orig-date-parser ,
        from-parser ,
        sender-parser ,
        reply-to-parser ,
        to-parser ,
        cc-parser ,
        bcc-parser ,
        message-id-parser ,
        in-reply-to-parser ,
        references-parser ,
        subject-parser ,
        comments-parser ,
        keywords-parser ,
        content-type-parser ,
        optional-field-parser ,
    ] choice* repeat0
    [
        mail-header new
        [
            [ second ] [ first ] bi dup >>writer-word
            [ swap drop 1quotation call( mail-header value -- mail-header ) ]
            [
                [ dup optional-fields>> ] 2dip
                swap 2array 1array append >>optional-fields
            ] if*
        ] reduce
    ] action ;

PEG: parse-mail ( str -- mail )
     fields-parser crlf-parser 2seq
     [ first input-slice [ seq>> ] [ from>> ] bi tail mail boa ] action ;
