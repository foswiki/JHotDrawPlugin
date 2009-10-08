package CH.ifa.draw.foswiki;

import java.awt.*;
import java.awt.event.*;
import java.util.*;
import java.io.*;
import java.net.*;

import CH.ifa.draw.framework.*;
import CH.ifa.draw.standard.*;
import CH.ifa.draw.figures.*;
import CH.ifa.draw.util.*;
import CH.ifa.draw.applet.*;
import CH.ifa.draw.contrib.*;
import CH.ifa.draw.appframe.*;

public class StandAlone implements Application {

    FoswikiFrame frame;
    Hashtable params;

    StandAlone(String[] args) {
        params = new Hashtable();
        for (int i = 0; i < args.length; i++) {
            int j = args[i].indexOf("=");
            if (j > 0) {
                String var = args[i].substring(0, j);
                String val = args[i].substring(j + 1);
                params.put(var, val);
            }
        }
        frame = new FoswikiFrame(this, null);
        frame.pack();
        frame.show();
    }

    /** Implement Application */
    public void showStatus(String s) {
        System.out.println("STATUS " + s);
    }

    /** Implement Application */
    public String getParameter(String name) {
        System.out.println("GETPARAMETER " + name + "=" + params.get(name));
        return (String) params.get(name);
    //return super.getParameter(name);
    }

    /** Implement Application */
    public InputStream getStream(String relURL) throws IOException {
        //return new URL(getCodeBase(), relURL);
        System.out.println("GETFILE " + relURL);
        return new FileInputStream(relURL);
    }

    /** Implement Application */
    public void popupFrame(String url, String title) {
        //getAppletContext().showDocument(url, title);
        System.out.println(title + " POPUPFRAME " + url);
    }

    public void pushSaveParam(String value) {
        System.out.println("Save " + value);
    }

    public void commitSaves() {
        System.out.println("Commit saves");
    }

    public static void main(String[] args) {
        StandAlone app = new StandAlone(args);
    }

    public void exit() {
        System.out.println("EXIT");
        System.exit(0);
    }
}
