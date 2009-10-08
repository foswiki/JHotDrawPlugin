/*
 * @(#)FoswikiDraw.java 5.1
 * Copyright 2000 by Peter Thoeny, Peter@Thoeny.com.
 * It is hereby granted that this software can be used, copied, 
 * modified, and distributed without fee provided that this 
 * copyright notice appears in all copies.
 * Portions Copyright (C) 2001 Motorola - All Rights Reserved
 * Copyright (C) 2008-2009 Foswiki Contributors
 */
package CH.ifa.draw.foswiki;

import java.awt.Label;

import java.util.Vector;

import CH.ifa.draw.appframe.LightweightDrawApplet;

public class FoswikiDraw extends LightweightDrawApplet {

    private boolean readyToSave;
    private boolean readyToExit;
    
    public void init() {
        String colors = getParameter("extracolors");
        init(new FoswikiFrame(this, colors));
        String drawPath = getParameter("drawingname");
        add(new Label("FoswikiDraw editing " + drawPath));
        readyToSave = false;
        readyToExit = false;
    }
    
    private Vector saveData = new Vector();
    
    public boolean readyToSave() {
        return readyToSave;
    }
      
    public boolean readyToExit() {
        return readyToExit;
    }
      
    public Object[] getSaveData() {
        Object[] save = saveData.toArray();
        saveData = new Vector();
        readyToSave = false;
        return save;
    }
    
    public void pushSaveParam(String value) {
        saveData.add(value);
     }

    public void commitSaves() {
        readyToSave = true;
    }

    public void exit() {
        readyToExit = true;
    }
}
