#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 34;
use Test::Exception;
use Test::Moose 'does_ok';

my $sort;
my $less;
my $up;
{
    package Stuff;
    use Moose;

    has '_options' => (
        traits   => ['Array'],
        is       => 'ro',
        isa      => 'ArrayRef[Int]',
        init_arg => 'options',
        default  => sub { [] },
        handles  => {
            'num_options'          => 'count',
            'has_no_options'       => 'empty',
            'map_options',         => 'map',
            'filter_options'       => 'grep',
            'find_option'          => 'first',
            'options'              => 'elements',
            'join_options'         => 'join',
            'get_option_at'        => 'get',
            'get_first_option'     => 'head',
            'all_but_first_option' => 'tail',
            'get_last_option'      => 'last',
            'sorted_options'       => 'sort',
            'less_than_five'       => [ grep => [ $less = sub { $_ < 5 } ] ],
            'up_by_one'            => [ map => [ $up = sub { $_ + 1 } ] ],
            'dashify'    => [ join => ['-'] ],
            'descending' => [ sort => [ $sort = sub { $_[1] <=> $_[0] } ] ],
        },
    );

}

my $stuff = Stuff->new( options => [ 1 .. 10 ] );
isa_ok( $stuff, 'Stuff' );

can_ok( $stuff, $_ ) for qw[
    _options
    num_options
    has_no_options
    map_options
    filter_options
    find_option
    options
    join_options
    get_option_at
    sorted_options
];

is_deeply( $stuff->_options, [ 1 .. 10 ], '... got options' );

ok( !$stuff->has_no_options, '... we have options' );
is( $stuff->num_options, 10, '... got 2 options' );
cmp_ok( $stuff->get_option_at(0), '==', 1,  '... get option 0' );
cmp_ok( $stuff->get_first_option, '==', 1,  '... get head' );
is_deeply( [ $stuff->all_but_first_option ], [ 2 .. 10 ], '... get tail' );
cmp_ok( $stuff->get_last_option,  '==', 10, '... get last' );

is_deeply(
    [ $stuff->filter_options( sub { $_ % 2 == 0 } ) ],
    [ 2, 4, 6, 8, 10 ],
    '... got the right filtered values'
);

is_deeply(
    [ $stuff->map_options( sub { $_ * 2 } ) ],
    [ 2, 4, 6, 8, 10, 12, 14, 16, 18, 20 ],
    '... got the right mapped values'
);

is( $stuff->find_option( sub { $_ % 2 == 0 } ), 2,
    '.. found the right option' );

is_deeply( [ $stuff->options ], [ 1 .. 10 ], '... got the list of options' );

is( $stuff->join_options(':'), '1:2:3:4:5:6:7:8:9:10',
    '... joined the list of options by :' );

is_deeply(
    [ $stuff->sorted_options ], [ sort ( 1 .. 10 ) ],
    '... got sorted options (default sort order)'
);
is_deeply(
    [ $stuff->sorted_options( sub { $_[1] <=> $_[0] } ) ],
    [ sort { $b <=> $a } ( 1 .. 10 ) ],
    '... got sorted options (descending sort order) '
);

throws_ok { $stuff->sorted_options('foo') }
qr/Argument must be a code reference/,
    'error when sort receives a non-coderef argument';

# test the currying
is_deeply( [ $stuff->less_than_five() ], [ 1 .. 4 ] );

is_deeply( [ $stuff->up_by_one() ], [ 2 .. 11 ] );

is( $stuff->dashify, '1-2-3-4-5-6-7-8-9-10' );

is_deeply( [ $stuff->descending ], [ reverse 1 .. 10 ] );

## test the meta

my $options = $stuff->meta->get_attribute('_options');
does_ok( $options, 'Moose::Meta::Attribute::Native::Trait::Array' );

is_deeply(
    $options->handles,
    {
        'num_options'          => 'count',
        'has_no_options'       => 'empty',
        'map_options',         => 'map',
        'filter_options'       => 'grep',
        'find_option'          => 'first',
        'options'              => 'elements',
        'join_options'         => 'join',
        'get_option_at'        => 'get',
        'get_first_option'     => 'head',
        'all_but_first_option' => 'tail',
        'get_last_option'      => 'last',
        'sorted_options'       => 'sort',
        'less_than_five'       => [ grep => [$less] ],
        'up_by_one'            => [ map => [$up] ],
        'dashify'              => [ join => ['-'] ],
        'descending'           => [ sort => [$sort] ],
    },
    '... got the right handles mapping'
);

is( $options->type_constraint->type_parameter, 'Int',
    '... got the right container type' );

dies_ok {
    $stuff->sort_in_place_options(undef);
}
'... sort rejects arg of invalid type';

