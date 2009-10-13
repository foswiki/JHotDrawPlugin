/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

package CH.ifa.draw.foswiki;

import java.awt.Dialog;
import java.awt.Frame;
import java.awt.Panel;
import java.awt.Label;
import java.awt.Button;
import java.awt.GridLayout;
import java.awt.FlowLayout;
import java.awt.event.ActionListener;
import java.awt.event.ActionEvent;

public class ExitVetoDialog extends Dialog implements ActionListener {

    private Button ok;
    private boolean result;
    
    public ExitVetoDialog(Frame parent) {

        super(parent, true);
        
        Panel p = new Panel();
        this.add(p);
        
        p.setLayout(new GridLayout(2,1));
            
        p.add(new Label("If you have any unsaved changes, they will be lost when you exit."));
               
        Panel b = new Panel();
        b.setLayout(new FlowLayout());
        p.add(b);
        b.add(ok = new Button("Yes, exit now"));
        Button cancel = new Button("No, don't exit yet");
        b.add(cancel);
        
        ok.addActionListener(this);
        cancel.addActionListener(this);

        this.setSize(300, 100);
        this.setLocation(100, 200);
        this.pack();
    }

    public void actionPerformed(ActionEvent evt) {
        if (evt.getSource() == ok) {
            result = true;
        } else {
            result = false;
        }
        this.dispose();
    }

    public static boolean ok(Frame parent) {
        ExitVetoDialog dlg = new ExitVetoDialog(parent);
        dlg.setVisible(true);
        return dlg.result;
    }
}

