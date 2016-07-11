#!/usr/bin/env perl

use Plack::App::Directory;
use Plack::App::File;
use Plack::Builder;
use Plack::Util;

my $sample_app = sub {
    my $env = shift;
    my $client_id = $env->{'REMOTE_ADDR'};

    return [
        '200',
        [ 'Content-Type' => 'text/plain' ],
        [ "Your IP address is ${client_id}." ],     # or IO::Handle-like object
    ];
};

my $debug_hider = sub {
    my $app = shift;
    return sub {
        my $env = shift;
        Plack::Util::response_cb($app->($env), sub {
            my $res     = shift;
            my $headers = Plack::Util::headers($res->[1]);
            if (   ! Plack::Util::status_with_no_entity_body($res->[0])
                && ($headers->get('Content-Type') || '') =~ m!^(?:text/html|application/xhtml\+xml)!) {

                my $content = q{
<script>
/* Only show Debug middleware on the "middleware-debug" slide. */
slideshow.on('showSlide', function (slide) {
    if (slide.properties.name === 'middleware-debug') {
        document.getElementById('plDebug').style.display = 'block';
    }
});
slideshow.on('hideSlide', function (slide) {
    document.getElementById('plDebug').style.display = 'none';
});
document.getElementById('plDebug').style.display = 'none';
</script>
                };

                return sub {
                    my $chunk = shift;
                    return unless defined $chunk;
                    $chunk =~ s!(?=</body>)!$content!i;
                    return $chunk;
                };
            }
        });
    };
};

builder {
    enable $debug_hider;
    enable 'Debug';

    mount '/myip'           => $sample_app;

    mount '/css'	    => Plack::App::Directory->new(root => 'css')->to_app;
    mount '/img'	    => Plack::App::Directory->new(root => 'img')->to_app;
    mount '/remark.min.js'  => Plack::App::File->new(file => 'remark.min.js')->to_app;
    mount '/'		    => Plack::App::File->new(file => 'slides-offline.html')->to_app;
};

