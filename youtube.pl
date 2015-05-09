use strict;
use vars qw($VERSION %IRSSI);
use Data::Dumper;

use LWP::UserAgent;

use Irssi;
$VERSION = '20150509';
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
# 20111024 - fixed bug that caused certain id's to not work with api, fixed typo
# 20111030 - FIXED.
# 20111101 - added a super regex courtesy of ridgerunner (http://stackoverflow.com/questions/5830387/php-regex-find-all-youtube-video-ids-in-string/5831191#5831191)
# 20111124 - apparently the super regex didn't allow links without http://, so I made that part optional
# 20150508 - now uses YouTube Data API v3
# 20150509 - now gets API Key from setting youtube_api_key
#
# usage:
# /script load youtube
# enjoy ;o)
#

# Load API key for YouTube Data API v3, needs to be genereted in the Google Developer Console
my $api_key;
Irssi::settings_add_str('youtube', 'youtube_api_key', 'API_KEY_HERE');
reload_settings();

sub reload_settings {
    $api_key = Irssi::settings_get_str('youtube_api_key');
}
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
    my $retval = uri_get($data); 
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
    # Super RegEx courtesy of ridgerunner
    # http://stackoverflow.com/questions/5830387/php-regex-find-all-youtube-video-ids-in-string/5831191#5831191
    if ($url =~ /(?:https?:\/\/)?(?:[0-9A-Z-]+\.)?(?:youtu\.be\/|youtube\.com\S*[^\w\-\s])([\w\-]{11})(?=[^\w\-]|$)(?![?=&+%\w]*(?:['"][^<>]*>|<\/a>))[?=&+%\w]*/ig) { 
        return "https://www.googleapis.com/youtube/v3/videos?part=snippet&id=$1&fields=items%2Fsnippet%2Ftitle&key=$api_key"
    } 
    return 0; 
} 
sub uri_get { 
    my ($data) = @_; 

    my $url = uri_parse($data); 

    if ($url)
    {
        my $ua = LWP::UserAgent->new(env_proxy=>1, keep_alive=>1, timeout=>5); 
        $ua->agent("irssi/$VERSION " . $ua->agent()); 

        my $req = HTTP::Request->new('GET', $url); 
        my $res = $ua->request($req);

        my $result_string = '';
        my $json = JSON->new->utf8;

        eval {
            my $json_data = $json->decode($res->content());

            if ($res->is_success()) { 
                eval {
                    $result_string = $json_data->{items}->[0]->{snippet}->{title};
                } 
                or do {
                    $result_string = "Request successful, parsing error";
                };
            } 
            else {
                eval {
                    $result_string = "Error $json_data->{error}->{code} $json_data->{error}->{message}";
                } or do {
                    $result_string = "Parsing error";
                };
            }
        } 
        or do {
            $result_string = "Error " . $res->status_line;
        };

        return $result_string; 
    }
} 

Irssi::signal_add_last('message public', 'uri_public'); 
Irssi::signal_add_last('message private', 'uri_private');
Irssi::signal_add_last('setup changed', 'reload_settings'); 