# Copyright (C) 2008, The Perl Foundation.
# $Id$

=head1 NAME

lib/uuid.pir - uuid library

=head1 DESCRIPTION

See original on L<http://www.tecgraf.puc-rio.br/~lhf/ftp/lua/#luuid/>

This implementation is based on F<runtime/parrot/library/uuid.pir>.

=head2 Functions

=over 4

=cut

.HLL 'Lua', 'lua_group'
.namespace [ 'Lua'; 'uuid' ]

.sub '__onload' :anon :load
#    print "__onload uuid\n"
    .const .Sub entry = 'luaopen_uuid'
    set_hll_global 'luaopen_uuid', entry
.end

.sub 'luaopen_uuid'

#    print "luaopen_uuid\n"
    load_bytecode 'uuid.pir'

    .local pmc _lua__GLOBAL
    _lua__GLOBAL = get_hll_global '_G'

    new $P1, 'LuaString'

    .local pmc _uuid
    new _uuid, 'LuaTable'
    set $P1, 'uuid'
    _lua__GLOBAL[$P1] = _uuid

    lua_register($P1, _uuid)

    .const .Sub _uuid_isvalid = 'isvalid'
    _uuid_isvalid.'setfenv'(_lua__GLOBAL)
    set $P1, 'isvalid'
    _uuid[$P1] = _uuid_isvalid

    .const .Sub _uuid_new = 'new'
    _uuid_new.'setfenv'(_lua__GLOBAL)
    set $P1, 'new'
    _uuid[$P1] = _uuid_new

    .const .Sub _uuid_time = 'time'
    _uuid_time.'setfenv'(_lua__GLOBAL)
    set $P1, 'time'
    _uuid[$P1] = _uuid_time

    new $P2, 'LuaString'

#    set $P2, "Copyright (C) 2008, The Perl Foundation"
#    set $P1, "_COPYRIGHT"
#    _uuid[$P1] = $P2

    set $P2, "uuid library for Lua on Parrot"
#    set $P1, "_DESCRIPTION"
    set $P1, "version"
    _uuid[$P1] = $P2

#    set $P2, "uuid ???"
#    set $P1, "_VERSION"
#    _uuid[$P1] = $P2

    .return (_uuid)
.end


=item C<uuid.new ([s])>

=cut

.sub 'new' :anon
    .param pmc str :optional
    .param pmc extra :slurpy
    .local pmc res
    $S1 = lua_optstring(1, str, '')
    $I0 = index $S1, 'r'
    unless $I0 == 0 goto L1
    $S0 = 'generate_random'
    goto L3
  L1:
    $I0 = index $S1, 't'
    unless $I0 == 0 goto L2
    $S0 = 'generate_time'
    goto L3
  L2:
    $S0 = 'generate'
  L3:
    $P0 = get_hll_global ['uuid'], $S0
    $P1 = $P0()
    $P0 = get_hll_global ['uuid'], 'get_string'
    $S0 = $P0($P1)
#    $S0 = $P1
    new res, 'LuaString'
    set res, $S0
    .return (res)
.end


=item C<uuid.isvalid (s)>

=cut

.sub 'isvalid' :anon
    .param pmc str :optional
    .param pmc extra :slurpy
    .local pmc res
    $S1 = lua_checkstring(1, str)
    $P0 = get_hll_global ['uuid'], 'parse'
    $I0 = $P0($S1)
    not $I0
    new res, 'LuaBoolean'
    set res, $I0
    .return (res)
.end


=item C<uuid.time (s)>

=cut

.sub 'time' :anon
    .param pmc str :optional
    .param pmc extra :slurpy
    $S1 = lua_checkstring(1, str)
    $P0 = get_hll_global ['uuid'], 'parse'
    ($I0, $P1) = $P0($S1)
    unless $I0 goto L1
    .return ()
  L1:
    .local pmc res
    new res, 'LuaNumber'
    $P0 = get_hll_global ['uuid'], 'time'
    $I0 = $P0($P1)
#    $I0 = $P1.'time'()
    set res, $I0
    .return (res)
.end


=back

=head1 AUTHORS

Francois Perrad

=cut


# Local Variables:
#   mode: pir
#   fill-column: 100
# End:
# vim: expandtab shiftwidth=4 ft=pir:
