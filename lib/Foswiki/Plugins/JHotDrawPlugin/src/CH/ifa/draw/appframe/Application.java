package CH.ifa.draw.appframe;

import java.io.IOException;
import java.io.InputStream;

/**
 * Interface to controlling application, either an applet or a java
 * application. Makes a DrawFrame independent of it's context.
 */
public interface Application {

    /** Show status string, eg in applet area */
    void showStatus(String s);

    /** Get command-line or applet parameter */
    String getParameter(String name);

    /** Get URL relative to the codebase of the app */
    InputStream getStream(String relURL) throws IOException;

    /** Popup a URL in a new frame */
    void popupFrame(String url, String title);

    void exit();

    void pushSaveParam(String param);
    
    void commitSaves();
}
