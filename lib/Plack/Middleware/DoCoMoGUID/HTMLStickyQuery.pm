package Plack::Middleware::DoCoMoGUID::HTMLStickyQuery;
use strict;
use warnings;
use parent 'Plack::Middleware';
use Plack::Util;
use HTML::StickyQuery::DoCoMoGUID;

sub call {
    my ($self, $env) = @_;
    my $res = $self->app->($env);
    if ( $res->[0] == 200 ) {
        my $headers = $res->[1];
        my $body = $res->[2];
        if ( Plack::Util::header_get('content-type') =~ m{text/html} ) {
            my $sticky = HTMLStickyQuery::DoCoMoGUID->new;
            $body = $sticky->sticky(arrayref => $body);
            $res->[2] = $body;
        }
    }

    return $res;
}

1;
__END__

=head1 NAME

Plack::Middleware::DoCoMoGUID::HTMLStickyQuery - added guid=ON to html content link.

=head1 SYNOPSIS

    use Plack::Builder;

    builder {
        enable_if { $_[0]->{HTTP_USER_AGENT} =~ /DoCoMo/i } 'DoCoMoGUID::HTMLStickyQuery';
    };

=head1 DESCRIPTION

Plack::Middleware::DoCoMoGUID::HTMLStickyQuery filter html content and added guid=ON parameter to
 all relative link or form action using HTML::StickyQuery::DoCoMoGUID.

=head1 AUTHOR

Keiji Yoshimi E<lt>walf443 at gmail dot comE<gt>

=head1 SEE ALSO

+<HTML::StickyQuery::DoCoMoGUID>, +<Plack::Middleware>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
