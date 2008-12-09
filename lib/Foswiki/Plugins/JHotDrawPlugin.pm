# Plugin for Foswiki - The Free and Open Source Wiki, http://foswiki.org/
#
# Copyright (C) 2000-2001 Andrea Sterbini, a.sterbini@flashnet.it
# Copyright (C) 2001-2006 Peter Thoeny, Peter@Thoeny.org
# Copyright (C) 2002-2006 Crawford Currie, cc@c-dot.co.uk
# Copyright (C) 2008 Foswiki Contributors
#
# For licensing info read LICENSE file in the Foswiki root.
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details, published at
# http://www.gnu.org/copyleft/gpl.html
#
# As per the GPL, removal of this notice is prohibited.

package Foswiki::Plugins::JHotDrawPlugin;

our $VERSION = '$Rev: 8154 $';
our $RELEASE = '9 Dec 2008';

sub initPlugin {
    Foswiki::Func::registerTagHandler( 'DRAWING', \&_handleDrawingMacro );
    # Don't need a REST handler, we just use upload
    return 1;
}

sub _handleDrawingMacro {
    my( $session, $attributes, $topic, $web ) = @_;

    my $drawingName = $attributes->{_DEFAULT} || 'untitled';
    $drawingName =~ Foswiki::Func::sanitizeAttachmentName($drawingName);

    my $mapFile = "$drawingName.map";
    my $imgParams = { src => "%ATTACHURLPATH%/$drawingName.gif" };

    # The edit URL is an oops script which is unauthenticated, so we have
    # to be sure we can change the topic before we can offer to edit
    my $canEdit = Foswiki::Func::checkAccessPermission(
        'CHANGE', Foswiki::Func::getCanonicalUserID(), undef, $topic, $web);

    my $editUrl = '';
    my $editLinkParams = {};
    my $edittext = 'Edit access denied';
    if ($canEdit ) {
        $editUrl = Foswiki::Func::getScriptUrl(
            $web, $topic, 'oops',
            template => 'jhotdraw',
            param1 => $drawingName);
        $editLinkParams->{href} = $editUrl;
        $edittext = Foswiki::Func::getPreferencesValue(
            "JHOTDRAWPLUGIN_EDIT_TEXT" ) ||
              "Edit drawing using Java applet (requires a Java enabled browser)";
        $edittext =~ s/%F%/$drawingName/g;
    }

    my $result = '';
    if ( Foswiki::Func::attachmentExists($web, $topic, $mapFile )) {
        my $map = Foswiki::Func::readAttachment($web, $topic, $mapFile);

        my $mapname = $drawingName;
        $imgParams->{usemap} = "#$mapname";

        # Unashamed hack to handle Web.TopicName links
        $map =~ s!href=(["'])(.*?)\1!_processHref($2, $web)!ge;

        Foswiki::Func::setPreferencesValue('MAPNAME', $mapname);
        Foswiki::Func::setPreferencesValue('FOSWIKIDRAW', $editUrl);
        Foswiki::Func::setPreferencesValue('EDITTEXT', $edittext);
        $map = Foswiki::Func::expandCommonVariables( $map, $topic );

        # Add an edit link just above the image if required
        my $editButton = Foswiki::Func::getPreferencesValue(
            "JHOTDRAWPLUGIN_EDIT_BUTTON" );

        if ( $canEdit && $editButton ) {
            $result = CGI::br().CGI::a($editLinkParams, 'Edit').CGI::br();
        }
        $result .= CGI::img($imgParams).$map;
    } else {
        # insensitive drawing; the whole image gets a rather more
        # decorative version of the edit URL
        $imgParams->{alt} = $edittext;
        $imgParams->{title} = $edittext;
        $result = CGI::img($imgParams);
        if ($canEdit) {
            $result = CGI::a({ href => $editUrl, title => $edittext },
                             $result);
        }
    }
    return $result;
}

sub _processHref {
    my ( $link, $defweb ) = @_;

    if ($link =~ m!^$Foswiki::regex{webNameRegex}\..*?(#\w+)$!) {
        $link =~ s/(#.*)$//;
        my $anchor = $1 || '';
        my ($web, $topic) = Foswiki::Func::normalizeWebTopicName(
            $defweb, $link);
        $link = "%SCRIPTURLPATH{view}%/$web/$topic$anchor";
    }
    return "href=\"$link\"";
}

1;
