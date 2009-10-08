/*
 * Dialog to get a new name for a drawing
 */
package CH.ifa.draw.foswiki;

import java.awt.Dialog;
import java.awt.Frame;
import java.awt.Panel;
import java.awt.Label;
import java.awt.Button;
import java.awt.GridLayout;
import java.awt.FlowLayout;
import java.awt.TextField;
import java.awt.event.ActionListener;
import java.awt.event.ActionEvent;

public class SaveAsDialog extends Dialog implements ActionListener {

    private TextField data;
    private Button ok;
    private String result;
    
    public SaveAsDialog(Frame parent, String value) {

        super(parent, true);
        
        Panel p = new Panel();
        this.add(p);
        
        p.setLayout(new GridLayout(1,2));
        
        Panel top = new Panel();
        top.setLayout(new FlowLayout());
        p.add(top);
        
        top.add(new Label("Save as:"));
        top.add(data = new TextField(value));

        Panel bottom = new Panel();
        bottom.setLayout(new FlowLayout());
        p.add(bottom);
        
        bottom.add(ok = new Button("OK"));
        Button cancel = new Button("Cancel");
        bottom.add(cancel);
        
        ok.addActionListener(this);
        cancel.addActionListener(this);

        this.setSize(300, 100);
        this.setLocation(100, 200);
        this.pack();
    }

    public void actionPerformed(ActionEvent evt) {
        if (evt.getSource() == ok) {
            result = data.getText();
        } else {
            result = null;
        }
        this.dispose();
    }

    public static String prompt(Frame parent, String value) {
        SaveAsDialog dlg = new SaveAsDialog(parent, value);
        dlg.setVisible(true);
        return dlg.result;
    }
}
