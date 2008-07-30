! Copyright (C) 2008 Slava Pestov.
! See http://factorcode.org/license.txt for BSD license.
USING: fry accessors kernel sequences sequences.private assocs words
namespaces classes.algebra combinators classes classes.tuple
classes.tuple.private continuations arrays byte-arrays strings
math math.partial-dispatch math.private slots generic
generic.standard generic.math
compiler.tree
compiler.tree.def-use
compiler.tree.propagation.info
compiler.tree.propagation.nodes
compiler.tree.propagation.slots
compiler.tree.propagation.inlining
compiler.tree.propagation.constraints ;
IN: compiler.tree.propagation.simple

! Propagation for straight-line code.

M: #introduce propagate-before
    value>> object <class-info> swap set-value-info ;

M: #push propagate-before
    [ literal>> <literal-info> ] [ out-d>> first ] bi
    set-value-info ;

: refine-value-infos ( classes values -- )
    [ refine-value-info ] 2each ;

: class-infos ( classes -- infos )
    [ <class-info> ] map ;

: set-value-infos ( infos values -- )
    [ set-value-info ] 2each ;

M: #declare propagate-before
    declaration>> [ <class-info> swap refine-value-info ] assoc-each ;

: predicate-constraints ( value class boolean-value -- constraint )
    [ [ is-instance-of ] dip t--> ]
    [ [ class-not is-instance-of ] dip f--> ]
    3bi /\ ;

: custom-constraints ( #call quot -- )
    [ [ in-d>> ] [ out-d>> ] bi append ] dip
    with-datastack first assume ;

: compute-constraints ( #call word -- )
    dup +constraints+ word-prop [ nip custom-constraints ] [
        dup predicate? [
            [ [ in-d>> first ] [ out-d>> first ] bi ]
            [ "predicating" word-prop ] bi*
            swap predicate-constraints assume
        ] [ 2drop ] if
    ] if* ;

: call-outputs-quot ( #call word -- infos )
    [ in-d>> [ value-info ] map ] [ +outputs+ word-prop ] bi*
    with-datastack ;

: foldable-call? ( #call word -- ? )
    "foldable" word-prop
    [ in-d>> [ value-info literal?>> ] all? ] [ drop f ] if ;

: fold-call ( #call word -- infos )
    [ in-d>> [ value-info literal>> ] map ]
    [ [ execute ] curry ]
    bi* with-datastack
    [ <literal-info> ] map ;

: default-output-value-infos ( #call word -- infos )
    "default-output-classes" word-prop
    [ class-infos ] [ out-d>> length object <class-info> <repetition> ] ?if ;

: output-value-infos ( #call word -- infos )
    {
        { [ 2dup foldable-call? ] [ fold-call ] }
        { [ dup tuple-constructor? ] [ propagate-tuple-constructor ] }
        { [ dup sequence-constructor? ] [ propagate-sequence-constructor ] }
        { [ dup +outputs+ word-prop ] [ call-outputs-quot ] }
        [ default-output-value-infos ]
    } cond ;

: do-inlining ( #call word -- ? )
    {
        { [ dup standard-generic? ] [ inline-standard-method ] }
        { [ dup math-generic? ] [ inline-math-method ] }
        { [ dup math-partial? ] [ inline-math-partial ] }
        { [ dup method-body? ] [ inline-method-body ] }
        [ 2drop f ]
    } cond ;

M: #call propagate-before
    dup word>> 2dup do-inlining [ 2drop ] [
        [ [ output-value-infos ] [ drop out-d>> ] 2bi set-value-infos ]
        [ compute-constraints ]
        2bi
    ] if ;

: propagate-input-classes ( node input-classes -- )
    class-infos swap in-d>> refine-value-infos ;

M: #call propagate-after
    dup word>> "input-classes" word-prop dup
    [ propagate-input-classes ] [ 2drop ] if ;
