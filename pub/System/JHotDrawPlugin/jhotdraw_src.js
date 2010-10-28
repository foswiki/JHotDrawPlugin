// Requires strikeone and behaviour
// This javascript runs under the applet and provides comms services. It's
// required because the applet has no access to the SID cookie.

var JHD = {
    poll_timer: null,

    start: function() {
        if (JHD.poll_timer == null)
            JHD.poll_timer = setTimeout("JHD.poll()", 500);
    },

    stop: function() {
        if (JHD.poll_timer != null)
            clearTimeout(JHD.poll_timer);
    },

    poll: function() {
        JHD.poll_timer = null;
        if (document.mhdapp.readyToSave()) {
            setTimeout("JHD.save()", 100);
        } else if (document.mhdapp.readyToExit()) {
            setTimeout("JHD.exit()", 100);
        } else {
            JHD.poll_timer = setTimeout("JHD.poll()", 500);
        }
    },

    exit: function() {
        window.location = document.saveform.viewurl.value;
    },

    save: function() {
        var url = document.saveform.action;
        var args = document.mhdapp.getSaveData();
        var i = 0;
        var drawing = args[i++];
        var form = [];
        form.push('Content-Disposition: form-data; name="topic"\r\n\r\n'
                  + document.saveform.topic.value);
        form.push('Content-Disposition: form-data; name="drawing"\r\n\r\n'
                  + drawing);

        try {
            foswikiStrikeOne(document.saveform);
            form.push(
                'Content-Disposition: form-data; name="validation_key"\r\n\r\n'
                + document.saveform.validation_key.value);
        } catch (e) {
            alert(e);
        }

        var file = [];
        while (i < args.length) {
            var ext = args[i++];
            var content = args[i++];
            form.push('Content-Disposition: form-data; name="'
                      + ext + '"\r\n\r\n' + content);
        }

        var xmlhttp = false;
        try {
            xmlhttp = new ActiveXObject("Msxml2.XMLHTTP");
        } catch (e) {
            try {
                xmlhttp = new ActiveXObject("Microsoft.XMLHTTP");
            } catch (E) {
                xmlhttp = false;
            }
        }

        if (!xmlhttp && typeof XMLHttpRequest!='undefined') {
            try {
                xmlhttp = new XMLHttpRequest();
            } catch (e) {
                xmlhttp = false;
            }
        }

        var sep;
        var request = form.join('\n');
        do {
            sep = Math.floor(Math.random() * 1000000000);
        } while (request.indexOf(sep) != -1);

        request = "--" + sep + "\r\n" 
        + form.join('\r\n--' + sep + "\r\n")
        + "\r\n--" + sep + "--\r\n";

        xmlhttp.open("POST", url, true);
        xmlhttp.setRequestHeader('Content-Type',
                                 "multipart/form-data; boundary=" + sep);
        xmlhttp.onreadystatechange = function() {
            if (xmlhttp.readyState == 4) {
                if (xmlhttp.status >= 400) {
                    // Something went wrong!
                    if (xmlhttp.responseText) {
                        alert(xmlhttp.responseText);
                        document.mhdapp.showStatus(xmlhttp.responseText);
                    }
                }
                JHD.start(); // restart polling
            }
        }
        xmlhttp.send(request)
    }
};

$(document).ready(function() {
	JHD.start();
});

