USING: alien.syntax kernel math prettyprint io math.parser
combinators vocabs.loader hardware-info.backend system ;
IN: hardware-info

: write-unit ( x n str -- )
    [ 2^ /i number>string write bl ] [ write ] bi* ;

: kb ( x -- ) 10 "kB" write-unit ;
: megs ( x -- ) 20 "MB" write-unit ;
: gigs ( x -- ) 30 "GB" write-unit ;

<< {
    { [ os windows? ] [ "hardware-info.windows" ] }
    { [ os linux? ] [ "hardware-info.linux" ] }
    { [ os macosx? ] [ "hardware-info.macosx" ] }
    { [ t ] [ f ] }
} cond [ require ] when* >>

: hardware-report. ( -- )
    "CPUs: " write cpus number>string write nl
    "Physical RAM: " write physical-mem megs nl ;
