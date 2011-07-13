# Plugin for Foswiki - The Free and Open Source Wiki, http://foswiki.org/
#
# Copyright (C) 2000-2001 Andrea Sterbini, a.sterbini@flashnet.it
# Copyright (C) 2001-2006 Peter Thoeny, Peter@Thoeny.org
# Copyright (C) 2002-2006 Crawford Currie, cc@c-dot.co.uk
# Copyright (C) 2008-2009 Foswiki Contributors
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

use strict;

use Assert;

use File::Temp ();
use MIME::Base64 ();
use Encode ();

our $VERSION = '$Rev$';
our $RELEASE = '29 Oct 2010';
our $SHORTDESCRIPTION = 'Java Applet based drawing editor';

sub initPlugin {
    Foswiki::Func::registerTagHandler( 'DRAWING', \&_DRAWING );

    Foswiki::Func::registerRESTHandler( 'edit', \&_restEdit );
    Foswiki::Func::registerRESTHandler( 'upload', \&_restUpload );

    return 1;
}

# Tag handler
sub _DRAWING {
    my ( $session, $attributes, $topic, $web ) = @_;

    my $drawingName = $attributes->{_DEFAULT} || 'untitled';
    $drawingName = ( Foswiki::Func::sanitizeAttachmentName($drawingName) )[0];

    my ($imgTime) =
      Foswiki::Func::getRevisionInfo($web, $topic, 0, "$drawingName.gif");
    my $imgParams = { src => "%ATTACHURLPATH%/$drawingName.gif?t=$imgTime" };

    # The edit URL is a rest handler, but we still like
    # to be sure we can change the topic before we can offer to edit
    my $canEdit = Foswiki::Func::getContext()->{authenticated}
      && Foswiki::Func::checkAccessPermission( 'CHANGE',
        Foswiki::Func::getCanonicalUserID(),
        undef, $topic, $web );

    my $editUrl        = '';
    my $editLinkParams = {};
    my $edittext       = 'Edit access denied';
    if ($canEdit) {
        $editUrl = Foswiki::Func::getScriptUrl(
            'JHotDrawPlugin', 'edit', 'rest',
            topic     => "$web.$topic",
            drawing   => $drawingName
        );
        $editLinkParams->{href} = $editUrl;
        $edittext =
          Foswiki::Func::getPreferencesValue("JHOTDRAWPLUGIN_EDIT_TEXT")
          || "Edit drawing using Java applet (requires a Java enabled browser)";
        $edittext =~ s/%F%/$drawingName/g;
    }

    my $result = '';
    my $mapFile = "$drawingName.map";
    if ( Foswiki::Func::attachmentExists( $web, $topic, $mapFile ) ) {
        my $map = Foswiki::Func::readAttachment( $web, $topic, $mapFile );

        my $mapname = $drawingName;
        $imgParams->{usemap} = "#$mapname";

        # Unashamed hack to handle Web.TopicName links
        $map =~ s!href=(["'])(.*?)\1!_processHref($2, $web)!ge;

        Foswiki::Func::setPreferencesValue( 'MAPNAME',     $mapname );
        Foswiki::Func::setPreferencesValue( 'FOSWIKIDRAW', $editUrl );
        Foswiki::Func::setPreferencesValue( 'EDITTEXT',    $edittext );

        # Handle if drawing is imported from a T*iki installation
        if ( $map =~ /%TWIKIDRAW%/ ) {
            Foswiki::Func::setPreferencesValue( 'TWIKIDRAW', $editUrl );
        }

        $map = Foswiki::Func::expandCommonVariables( $map, $topic );

        # Add an edit link just above the image if required
        my $editButton =
          Foswiki::Func::getPreferencesValue("JHOTDRAWPLUGIN_EDIT_BUTTON");

        if ( $canEdit && $editButton ) {
            $result = CGI::br() . CGI::a( $editLinkParams, 'Edit' ) . CGI::br();
        }
        $result .= CGI::img($imgParams) . $map;
    }
    else {

        # insensitive drawing; the whole image gets a rather more
        # decorative version of the edit URL
        $imgParams->{alt}   = $edittext;
        $imgParams->{title} = $edittext;
        $result             = CGI::img($imgParams);
        if ($canEdit) {
            $result =
              CGI::a( { href => $editUrl, title => $edittext }, $result );
        }
    }
    return $result;
}

sub _processHref {
    my ( $link, $defweb ) = @_;

    # Skip processing naked anchor links, protocol links, and special macros
    unless ( $link =~
        m/^(%FOSWIKIDRAW%|%TWIKIDRAW%|#|$Foswiki::cfg{LinkProtocolPattern})/ )
    {

        my $anchor = '';
        if ( $link =~ s/(#.*)$// ) {
            $anchor = $1;
        }

        my ( $web, $topic ) =
          Foswiki::Func::normalizeWebTopicName( $defweb, $link );

        $link = "%SCRIPTURLPATH{view}%/$web/$topic$anchor";
    }

    return "href=\"$link\"";
}

sub returnRESTResult {
    my ( $response, $status, $text ) = @_;

    $response->header(
        -status  => $status,
        -type    => 'text/plain',
        -charset => 'UTF-8'
       );
    $response->print($text);

    print STDERR $text if ( $status >= 400 );
}

sub _getTopic {
    my ( $session, $plugin, $verb, $response ) = @_;
    my $query = Foswiki::Func::getCgiQuery();
    my ( $web, $topic ) =
      Foswiki::Func::normalizeWebTopicName( undef, $query->param('topic') );

    # Check that we have access to the topic
    unless (Foswiki::Func::checkAccessPermission(
        'CHANGE', Foswiki::Func::getCanonicalUserID(), undef, $topic, $web )) {
        returnRESTResult( $response, 401, "Access denied");
        return ();
    }
    $web = Foswiki::Sandbox::untaint(
        $web, \&Foswiki::Sandbox::validateWebName );
    $topic = Foswiki::Sandbox::untaint( $topic,
        \&Foswiki::Sandbox::validateTopicName );
    unless ( defined $web && defined $topic ) {
        returnRESTResult( $response, 401, "Access denied" );
        return ();
    }
    unless ( Foswiki::Func::checkAccessPermission(
        'CHANGE', Foswiki::Func::getWikiName(), undef, $topic, $web )) {
        returnRESTResult( $response, 401, "Access denied" );
        return ();
    }
    return ($web, $topic);
}

# REST handler
sub _restEdit {
    my ( $session, $plugin, $verb, $response ) = @_;
    my ($web, $topic) = _getTopic( @_ );
    return unless $web && $topic;

    my $query = Foswiki::Func::getCgiQuery();
    my $drawing = $query->param('drawing');
    unless ($drawing) {
        returnRESTResult( $response, 400, "No drawing" );
        return;
    }
    Foswiki::Func::setPreferencesValue('DRAWINGNAME', $drawing);
    my $src = (DEBUG) ? '_src' : '';
    Foswiki::Func::addToZone( 'script', 'JHOTDRAWPLUGIN', <<"JS", 'JQUERYPLUGIN::FOSWIKI');
<script type="text/javascript" src="$Foswiki::cfg{PubUrlPath}/$Foswiki::cfg{SystemWebName}/JHotDrawPlugin/jhotdraw$src.js"></script>
JS

    my $template = Foswiki::Func::loadTemplate('jhotdraw');
    $template = Foswiki::Func::expandCommonVariables($template);
    return Foswiki::Func::renderText($template);
}

sub _unescape {
    my $d = shift;
    $d =~ s/%([\da-f]{2})/chr(hex($1))/gei;
    return $d;
}

# REST handler
sub _restUpload {
    my ( $session, $plugin, $verb, $response ) = @_;
    my $query = Foswiki::Func::getCgiQuery();

    if ( $Foswiki::cfg{Validation}{Method} eq 'strikeone' ) {
        require Foswiki::Validation;
        my $nonce = $query->param('validation_key');
        if ( !defined($nonce)
            || !Foswiki::Validation::isValidNonce( $session->getCGISession(),
                $nonce ) )
        {
            returnRESTResult( $response, 403, "Invalid validation key" );
            return;
        }
    }
    
    my ($web, $topic) = _getTopic( @_ );

    # Basename of the drawing
    my $fileName    = $query->param('drawing');
    ASSERT($fileName, $query->Dump()) if DEBUG;

    my $origName = $fileName;

    # SMELL: call to unpublished function
    ( $fileName, $origName ) =
      Foswiki::Sandbox::sanitizeAttachmentName($fileName);

    # Save a file for each file type
    my @errors;
    foreach my $ftype (qw(draw gif map svg)) {
        my $content = $query->param($ftype);
        next unless defined $content;
        if ($ftype eq 'gif') {
            # GIF is passed base64 encoded
            $content = MIME::Base64::decode_base64($content);
        }
        my $ft = new File::Temp(); # will be unlinked on destroy
        my $fn = $ft->filename();
        binmode($ft);
        print $ft $content;
        close($ft);

        my $error = Foswiki::Func::saveAttachment(
            $web, $topic,
            "$fileName.$ftype",
            {
                dontlog     => !$Foswiki::cfg{Log}{upload},
                comment     => "JHotDrawPlugin file",
                filedate    => time(),
                file        => $fn,
            });
        if ($error) {
            print STDERR "Attachment save error $error\n";
            push(@errors, $error );
        }
    }

    if (scalar(@errors)) {
        print STDERR "JHotDraw SAVE FAILED\n";
        returnRESTResult( $response, 500, join(' ', @errors ));
    } else {
        returnRESTResult( $response, 200, 'OK');
    }

    return undef;
}

1;
