use strict;
use warnings;
use Test::More;

use Encode;
use HTML::TreeBuilder::XPath;
use HTTP::Request;
use HTTP::Request::Common;
use Plack::Builder;
use Plack::Request;
use Plack::Test;

for my $middleware ( qw( DoCoMoGUID ) ) {
    subtest $middleware => sub {
        subtest 'do filter case' => sub {
            test_psgi(
                app => sub {
                    my $env = shift;
                    my $app = builder {
                        enable 'Lint';
                        enable $middleware;
                        enable 'Lint';
                        sub {
                            my $env = shift;
                            my $req = Plack::Request->new($env);
                            sub {
                                my $respond = shift;
                                my $writer = $respond->(['302',[Location => $req->uri->as_string] ]);
                                $writer->write('');
                                $writer->close;
                                return;
                            }
                        };
                    };
                    $app->($env);
                },
                client => sub {
                    my $cb = shift;
                    {
                        my $req = HTTP::Request->new(GET => "http://localhost/hello?foo=bar");
                        my $res = $cb->($req);
                        is($res->code, 302, 'redirect ok');
                        is($res->header('location'), 'http://localhost/hello?guid=ON&foo=bar', 'guid=ON should set');
                    }
                    {
                        my $req = HTTP::Request->new(GET => "http://localhost/hello?foo=bar&guid=FOO");
                        my $res = $cb->($req);
                        is($res->code, 302, 'redirect ok');
                        is($res->header('location'), 'http://localhost/hello?foo=bar&guid=FOO', 'should not append guid=ON');
                    }
                },
            );

            done_testing();
        };

        subtest 'success case' => sub {
            for my $content_type ( qw{ text/html application/xhtml+xml } ) {
                subtest $content_type => sub {
                    our $INPUT_BODY = "";
                    test_psgi(
                        app => sub {
                            my $env = shift;
                            my $app = builder {
                                enable 'Lint';
                                enable $middleware;
                                enable 'Lint';
                                sub {
                                    my $env = shift;

                                    $INPUT_BODY = <<"...";

<html>
    <head></head>
    <body>
        <a class="should_replace1" href="/foo?foo=bar">foo</a>
        <a class="should_replace2" href="relative?foo=bar">あいうえお</a>
        <a class="should_not_replace" href="http://example.com/?foo=bar">かきくけこ</a>

        <form method="POST" action="/foo?foo=bar">
        </form>
    </body>
</html>
...

$INPUT_BODY = Encode::encode_utf8($INPUT_BODY);
#[200, [ 'Content-Type' => $content_type, 'Content-Length' => length($INPUT_BODY) ], [ $INPUT_BODY ] ];
                                    sub {
                                        my $respond = shift;
                                        my $writer = $respond->(['200',['Content-Type' => $content_type, 'Content-Length' => length($INPUT_BODY)] ]);
                                        $writer->write($INPUT_BODY);
                                        $writer->close;
                                    }
                                };
                            };
                            $app->($env);
                        },
                        client => sub {
                            my $cb = shift;
                            my $req = HTTP::Request->new(GET => "http://localhost/hello?foo=bar&guid=ON");
                            my $res = $cb->($req);
                            unless ( $res->is_success ) {
                                die $res->content;
                            }
                            isnt(length($INPUT_BODY), $res->header('Content-Length'), "should change Content-Length");
                            my $tree = HTML::TreeBuilder::XPath->new;
                            $tree->parse(Encode::decode_utf8($res->content));
                            my $node1 = $tree->findnodes('//a[@class="should_replace1"]');
                            is($node1->[0]->attr('href'), '/foo?guid=ON&foo=bar', 'should_replace1 ok');

                            my $node2 = $tree->findnodes('//a[@class="should_replace2"]');
                            is($node2->[0]->attr('href'), 'relative?guid=ON&foo=bar', 'should_replace2 ok');

                            my $node3 = $tree->findnodes('//a[@class="should_not_replace"]');
                            is($node3->[0]->attr('href'), 'http://example.com/?foo=bar', 'should_not_replace ok');
                        },
                    );
                    done_testing;
                };
            }

            done_testing();
        };

        subtest 'do filter case' => sub {
            test_psgi(
                app => sub {
                    my $env = shift;
                    my $app = builder {
                        enable 'Lint';
                        enable $middleware;
                        enable 'Lint';
                        sub {
                            sub {
                                my $respond = shift;
                                my $writer = $respond->(['200',[] ]);
                                $writer->write('hello');
                                $writer->close;
                            }
                        };
                    };
                    $app->($env);
                },
                client => sub {
                    my $cb = shift;
                    {
                        my $req = HTTP::Request->new(GET => "http://localhost/hello?foo=bar");
                        my $res = $cb->($req);
                        is($res->code, 302, 'redirect ok')
                            or diag($res->content);
                        is($res->header('location'), 'http://localhost/hello?guid=ON&foo=bar', 'guid=ON should set');
                    }
                    {
                        my $req = HTTP::Request->new(GET => "http://localhost/hello?foo=bar&guid=FOO");
                        my $res = $cb->($req);
                        is($res->code, 200, 'redirect should not work')
                            or diag($res->content);
                    }

                    {
                        my $req = POST "http://localhost/hello", [
                            foo => 'bar',
                            guid => 'FOO',
                        ];
                        my $res = $cb->($req);
                        is($res->code, 200, 'redirect should not work')
                            or diag($res->content);
                    }
                },
            );

            done_testing();
        };
        done_testing;
    };
}
done_testing();
