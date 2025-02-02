package Plack::Middleware::DoCoMoGUID::HTMLStickyQuery;
use strict;
use warnings;
use parent 'Plack::Middleware';
use Plack::Util;
use HTML::StickyQuery::DoCoMoGUID;

sub call {
    my ($self, $env) = @_;
    my $res = $self->app->($env);

    $self->response_cb($res, sub {
        my $res = shift;

        my @chunk;
        sub {
            my $chunk = shift;

            if ( $res->[0] == 200 ) {
                my $headers = $res->[1];
                my $content_type = Plack::Util::header_get($res->[1], 'content-type');
                if ( $content_type && $content_type =~ m{html} ) {
                    if ( defined $chunk ) {
                        push @chunk, $chunk;
                        return "";
                    }
                    elsif (@chunk) {
                        my $sticky = HTML::StickyQuery::DoCoMoGUID->new;
                        $sticky->{sticky}->utf8_mode(1);
                        my $body = join("", @chunk);
                        $body = $sticky->sticky(
                            scalarref => \$body,
                            ( $self->{params} ? ( param => $self->{params} ) : () ),
                        );
                        return $body;
                    }
                }
            }

            return $chunk;
        };
    });
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

or add check param

    use Plack::Builder;

    builder {
        enable_if { $_[0]->{HTTP_USER_AGENT} =~ /DoCoMo/i } 'DoCoMoGUID::HTMLStickyQuery' params => +{ 'foo' => 'bar' };
    };

this will also append foo parameter to link or form.

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
