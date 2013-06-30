# --
# Kernel/System/FAQ/State.pm - faq state functions
# Copyright (C) 2001-2013 OTRS AG, http://otrs.org/
# --
# $Id: State.pm,v 1.3 2013-06-30 00:45:04 cr Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::FAQ::State;

use strict;
use warnings;

=head1 NAME

Kernel::System::FAQ::State - sub module of Kernel::System::FAQ

=head1 SYNOPSIS

All faq state functions.

=head1 PUBLIC INTERFACE

=over 4

=cut

=item StateAdd()

add a state

    my $Success = $FAQObject->StateAdd(
        Name   => 'public',
        TypeID => 1,
        UserID => 1,
    );

Returns:

    $Success = 1;               # or undef if state could not be added

=cut

sub StateAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(Name TypeID UserID)) {
        if ( !$Param{$Argument} ) {
            $Self->{LogObject}->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }

    return if !$Self->{DBObject}->Do(
        SQL => '
            INSERT INTO faq_state (name, type_id)
            VALUES ( ?, ? )',
        Bind => [ \$Param{Name}, \$Param{TypeID} ],
    );

    return 1;
}

=item StateGet()

get a state as hash

    my %State = $FAQObject->StateGet(
        StateID => 1,
        UserID  => 1,
    );

Returns:

    %State = (
        StateID  => 1,
        Name     => 'internal (agent)',
        TypeID   => 1,
    );

=cut

sub StateGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(StateID UserID)) {
        if ( !$Param{$Argument} ) {
            $Self->{LogObject}->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }

    # sql
    return if !$Self->{DBObject}->Prepare(
        SQL => '
            SELECT id, name, type_id
            FROM faq_state
            WHERE id = ?',
        Bind  => [ \$Param{StateID} ],
        Limit => 1,
    );

    my %Data;
    while ( my @Row = $Self->{DBObject}->FetchrowArray() ) {
        %Data = (
            StateID => $Row[0],
            Name    => $Row[1],
            TypeID  => $Row[2],
        );
    }

    return %Data;
}

=item StateList()

get the state list as hash

    my %States = $FAQObject->StateList(
        UserID => 1,
    );

Returns:

    %States = (
        1 => 'internal (agent)',
        2 => 'external (customer)',
        3 => 'public (all)',
    );

=cut

sub StateList {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{UserID} ) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => 'Need UserID!',
        );
        return;
    }

    # sql
    return if !$Self->{DBObject}->Prepare(
        SQL => '
            SELECT id, name
            FROM faq_state'
    );

    my %List;
    while ( my @Row = $Self->{DBObject}->FetchrowArray() ) {
        $List{ $Row[0] } = $Row[1];
    }

    return %List;
}

=item StateUpdate()

update a state

    my Success = $FAQObject->StateUpdate(
        StateID => 1,
        Name    => 'public',
        TypeID  => 1,
        UserID  => 1,
    );

Returns:

    Success = 1;             # or undef if state could not be updated

=cut

sub StateUpdate {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(StateID Name TypeID UserID)) {
        if ( !$Param{$Argument} ) {
            $Self->{LogObject}->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }

    # sql
    return if !$Self->{DBObject}->Do(
        SQL => '
            UPDATE faq_state
            SET name = ?, type_id = ?,
            WHERE id = ?',
        Bind => [ \$Param{Name}, \$Param{TypeID}, \$Param{StateID} ],
    );

    return 1;
}

=item StateTypeGet()

get a state as hashref

    my $StateTypeHashRef = $FAQObject->StateTypeGet(
        StateID => 1,
        UserID  => 1,
    );

Or

    my $StateTypeHashRef = $FAQObject->StateTypeGet(
        Name    => 'internal',
        UserID  => 1,
    );

Returns:

    $StateTypeHashRef = {
        'StateID' => 1,
        'Name'    => 'internal',
    };

=cut

sub StateTypeGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{UserID} ) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => "Need UserID!",
        );
        return;
    }

    my $SQL = '
        SELECT id, name
        FROM faq_state_type
        WHERE';
    my @Bind;
    my $CacheKey = 'StateTypeGet::';
    if ( defined $Param{StateID} ) {
        $SQL .= ' id = ?';
        push @Bind, \$Param{StateID};
        $CacheKey .= 'ID::' . $Param{StateID};
    }
    elsif ( defined $Param{Name} ) {
        $SQL .= ' name = ?';
        push @Bind, \$Param{Name};
        $CacheKey .= 'Name::' . $Param{Name};
    }

    # check cache
    my $Cache = $Self->{CacheObject}->Get(
        Type => 'FAQ',
        Key  => $CacheKey,
    );
    return $Cache if $Cache;

    # sql
    return if !$Self->{DBObject}->Prepare(
        SQL  => $SQL,
        Bind => \@Bind,
    );

    my %Data;
    while ( my @Row = $Self->{DBObject}->FetchrowArray() ) {
        %Data = (
            StateID => $Row[0],
            Name    => $Row[1],
        );
    }

    # cache result
    $Self->{CacheObject}->Set(
        Type  => 'FAQ',
        Key   => $CacheKey,
        Value => \%Data,
        TTL   => 60 * 60 * 24 * 2,
    );

    return \%Data;
}

=item StateTypeList()

get the state type list as hashref

    my $StateTypeHashRef = $FAQObject->StateTypeList(
        UserID => 1,
    );

Returns:

    $StateTypeHashRef = {
        1 => 'internal',
        3 => 'public',
        2 => 'external',
    };

=cut

sub StateTypeList {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{UserID} ) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => 'Need UserID!',
        );
        return;
    }

    # build SQL
    my $SQL = '
        SELECT id, name
        FROM faq_state_type';

    # types are given
    if ( $Param{Types} ) {

        # copy $Param{Types} to a local value since it will be changed, if the reference value is
        # changed it will bring side effects
        my @Types = @{ $Param{Types} };

        # quote the types and add single quotes around them
        for my $Type (@Types) {
            $Type = "'" . $Self->{DBObject}->Quote($Type) . "'";
        }

        # create string
        my $InString = join ', ', @Types;
        $SQL .= ' WHERE name IN (' . $InString . ')';
    }

    # prepare SQL
    return if !$Self->{DBObject}->Prepare( SQL => $SQL );

    # fetch the result
    my %List;
    while ( my @Row = $Self->{DBObject}->FetchrowArray() ) {
        $List{ $Row[0] } = $Row[1];
    }

    return \%List;
}

1;

=back

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (http://otrs.org/).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut

=head1 VERSION

$Revision: 1.3 $ $Date: 2013-06-30 00:45:04 $

=cut
