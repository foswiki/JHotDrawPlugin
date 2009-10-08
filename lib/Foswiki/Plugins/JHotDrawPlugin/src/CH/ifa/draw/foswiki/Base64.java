/*
 * Taken from code on Wikipedia
 */

package CH.ifa.draw.foswiki;

/**
 *
 * @author crawford
 */
public class Base64 {
    final static String range = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    final static char[] b64c = range.toCharArray();

    public static String encode(char[] input) {
        /* Debug
         for (int i = 0; i < input.length; i++) {
            if (i > 0 && (i % 16) == 0) {
                System.out.println();
            }
            System.out.print(Integer.toOctalString((int)input[i]&0xFF) + " ");
        }
        System.out.println();*/
        String result = "", padding = "";

        if (input.length % 3 > 0) {
            for (int padCount = input.length % 3; padCount < 3; padCount++) {
                padding += "=";
            }
        }

        for (int index = 0; index < input.length;) {
            if (index > 0 && (index / 3 * 4) % 76 == 0) {
                result += "\r\n";
            }

            // Combine to form a 24bit number
            int n = (((int)input[index++] & 0xFF) << 16);
            if (n < 0) throw new RuntimeException("Cock");
            if (index < input.length) {
                n +=  (((int)input[index++] & 0xFF) << 8);
                if (index < input.length) {
                    n += input[index++] & 0xFF;
                }
            }

            // Turn 8bit per char number into a 6bit per char number
            int n1 = (n >> 18) & 63,
                    n2 = (n >> 12) & 63,
                    n3 = (n >> 6) & 63,
                    n4 = n & 63;

            result += "" + range.charAt(n1) + range.charAt(n2) + range.charAt(n3) + range.charAt(n4);
        }

        result = result.substring(0, result.length() - padding.length()) + padding;
        return result;
    }

    public static String decode(String input) {
        //Remove new lines
        input = input.replace("\r\n", "");

        //Turn padding into empty bytes
        String padding = (input.charAt(input.length() - 1) == '=' ? (input.charAt(input.length() - 2) == '=' ? "AA" : "A") : "");
        String result = "";

        input = input.substring(0, input.length() - padding.length()) + padding;

        for (int index = 0; index < input.length(); index += 4) {
            //make a 24bit number from (4) 6bit per char numbers
            int n = (range.indexOf(input.charAt(index + 0)) << 18) +
                    (range.indexOf(input.charAt(index + 1)) << 12) +
                    (range.indexOf(input.charAt(index + 2)) << 6) +
                    range.indexOf(input.charAt(index + 3));

            //turn 24bit number into (3) 8bit per char numbers
            result += "" + (char) ((n >>> 16) & 255) + (char) ((n >>> 8) & 255) + (char) (n & 255);
        }

        return result.substring(0, result.length() - padding.length());
    }
}
