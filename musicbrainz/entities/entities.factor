USING: strings calendar sequences kernel math ;
IN: musicbrainz.entities

SINGLETONS:
    person group orchestra choir character other
    album single ep broadcast
    compilation soundtrack spokenword interview audiobook audio-drama live remix dj-mix mixtape/street
    male female
    country subdivision county municipality city district island
    search-hint artist-name
    official promotional bootleg pseudo-release
    normal high low
    ;

UNION: primary-release-group-type
    album single ep broadcast other ;

UNION: secondary-release-group-type
    compilation soundtrack spokenword interview audiobook audio-drama live remix dj-mix mixtape/street ;

UNION: artist-type
    person group orchestra choir character other ;

UNION: area-type
    country subdivision county municipality city district island ;

UNION: alias-type search-hint artist-name ;

UNION: artist-gender
    male female ;

UNION: release-status
    official promotional bootleg pseudo-release ;

UNION: release-quality
    normal high low ;

TUPLE: entity
    { mbid string } ;

TUPLE: alias
    { name string }
    { sort-name string }
    { type maybe{ alias-type } }
    { locale maybe{ string } } ;

TUPLE: life-span
    { begin timestamp }
    { end maybe{ timestamp } }
    { ended? maybe{ boolean } } ;

TUPLE: area < entity
    { name string }
    { type maybe{ area-type }  }
    { sort-name maybe{ string } }
    { iso-codes maybe{ sequence } }
    { begin-date maybe{ timestamp } } ;

TUPLE: artist < entity
    { name string }
    { sort-name string }
    { disambiguation maybe{ string } }
    { life-span maybe{ life-span } }
    { country maybe{ string } }
    { isnis maybe{ sequence } } 
    { type maybe{ artist-type } }
    { gender maybe{ artist-gender } }
    { area maybe{ area } }
    { aliases maybe{ sequence } }
    { begin-area maybe{ area } } ;

TUPLE: text-representation
    { language string }
    { script string } ;

TUPLE: cover-art-archive
    { artwork? boolean }
    { count number }
    { front? boolean }
    { back? boolean } ;

TUPLE: release-event
    { date timestamp }
    { area maybe{ area } } ;

TUPLE: release < entity
    { title string }
    { status maybe{ release-status } }
    { quality maybe{ release-quality } }
    { disambiguation maybe{ string } }
    { date maybe{ timestamp } }
    { country maybe{ string } }
    { text-representation maybe{ text-representation } }
    { barcode maybe{ string } }
    { asin maybe{ string } }
    { release-events maybe{ sequence } }
    { packaging maybe{ string } }
    { mediums maybe{ sequence } }
    { artist maybe{ artist } }
    { label-info maybe{ sequence } }
    { cover-art-archive maybe{ cover-art-archive } } ;

TUPLE: collection < entity
    { name string }
    { editor string }
    { releases maybe{ sequence } } ;

TUPLE: recording < entity
    { title string }
    { length integer }
    { artist artist } ;

TUPLE: track < entity
    { position integer }
    { number integer }
    { length integer }
    { recording recording } ;

TUPLE: medium
    { position integer }
    { number integer }
    { format string }
    { dics sequence }
    { tracks sequence } ;

TUPLE: label < entity
    { type string }
    { name string }
    { sort-name maybe{ string } }
    { disambiguation maybe{ string } }
    { aliases maybe{ sequence } } ;
