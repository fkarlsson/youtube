use strict;
use vars qw($VERSION %IRSSI);

use LWP::UserAgent;

use Irssi;
$VERSION = '20111014';
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
#
# usage:
# /script load youtube
# enjoy ;o)
#


sub htmlfix {
	my $s = shift;
	$s =~ s!&amp;!&!g;
	$s =~ s!&quot;!"!g;
	$s =~ s!&rsquo;!'!g;
	$s =~ s!&\#039;!'!g;
	$s =~ s!&\#39;!'!g;
	$s =~ s!&ndash;!-!g;
	$s =~ s!&lt;!<!g;
	$s =~ s!&gt;!>!g;
	$s =~ s!</?br\s?/?>! !g;
	$s =~ s!\(<a.+>more</a>\)!!gi; # remove more
	$s =~ s!<a.+>.+</a>!!g; # remove links
	$s =~ s/\s+$//g; # last but not least remove tailing blanks
	return $s;
}

sub youtube {
	my ( $server, $msg, $nick, $addr, $target ) = @_;
	my $window = $server->window_find_item($target);

	if ($msg =~ /((youtube\.com\/watch\?).*v=|youtu\.be\/)(.{11})/) {
		my $ua = LWP::UserAgent->new;
		my $r = $ua->get("http://m.youtube.com/details?v=$3&warned=1&hl=en&fulldescription=1");
		Irssi::signal_continue(@_);
		return unless defined $r;

		# yes i know, parsing html with regular expressions is stupid
		# but i want to keep the dependencies as minimal as possible
		$r->content =~ /<title>YouTube\s-\s(.+)<\/title>/;
		if (defined $1) {
			$window->command("echo ".chr(3)."0"."YouTube:".chr(3)." ".htmlfix($1));
		}
	}
}

Irssi::signal_add_first('message public', \&youtube);