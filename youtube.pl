use strict;
use vars qw($VERSION %IRSSI);
use Data::Dumper;

use LWP::UserAgent;

use Irssi;
$VERSION = '20111023';
%IRSSI = (
    authors     => 'tuqs',
    contact     => 'tuqs@core.ws',
    name        => 'youtube',
    description => 'shows the title and description from the video',
    license     => 'Public Domain',
    changed     => $VERSION,
);


#
# 20081105 - function rewrite
# 20081226 - fixed regex
# 20090206 - some further fixes
# 20110913 - added support for youtu.be links
# 20111014 - changed regex so that it finds the v parameter even if it's not first
# 20111014 - added &#39; to htmlfix list
# 20111023 - improved regex and now uses youtube api instead
# 20111023 - improved regex some more and added detection of removed videos >:)
#
# usage:
# /script load youtube
# enjoy ;o)
#

sub uri_public { 
    my ($server, $data, $nick, $mask, $target) = @_; 
    my $retval = uri_get($data); 
    my $win = $server->window_item_find($target); 
    Irssi::signal_continue(@_);

    if ($win) { 
        $win->print("%_YouTube:%_ $retval", MSGLEVEL_CRAP) if $retval; 
    } else { 
        Irssi::print("%_YouTube:%_ $retval") if $retval; 
    } 
} 
sub uri_private { 
    my ($server, $data, $nick, $mask) = @_; 
    my $retval = spotifyuri_get($data); 
    my $win = Irssi::window_find_name('(msgs)'); 
    Irssi::signal_continue(@_);

    if ($win) { 
        $win->print("%_YouTube:%_ $retval", MSGLEVEL_CRAP) if $retval; 
    } else { 
        Irssi::print("%_YouTube:%_ $retval") if $retval; 
    } 
} 
sub uri_parse { 
    my ($url) = @_; 
    if ($url =~ /(youtube\.com\/|youtu\.be\/).*([a-zA-Z0-9\-_]{11})/) { 
        return "http://gdata.youtube.com/feeds/api/videos?q=$2&max-results=1&v=2&alt=jsonc";
    } 
    return 0; 
} 
sub uri_get { 
    my ($data) = @_; 

    my $url = uri_parse($data); 

    my $ua = LWP::UserAgent->new(env_proxy=>1, keep_alive=>1, timeout=>5); 
    $ua->agent("irssi/$VERSION " . $ua->agent()); 

    my $req = HTTP::Request->new('GET', $url); 
    my $res = $ua->request($req);

    if ($res->is_success()) { 
        my $json = JSON->new->utf8;
        my $json_data = $json->decode($res->content());
        my $result_string = '';

        eval {
            $result_string = @{$json_data->{data}->{items}}[0]->{title};
        } or do {
            $result_string = "Video error!";
        };

        return $result_string; 
    } 
    return 0;
} 

Irssi::signal_add_last('message public', 'uri_public'); 
Irssi::signal_add_last('message private', 'uri_private'); 