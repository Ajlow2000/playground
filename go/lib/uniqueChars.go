package lib

import "strings"

const input0 = "Cannot create STA. Active STA <meta STA : 00.4018.002.XXX /><a href=\"http://ajl-w11-wc12.sram.com/Windchill/app/#ptc1/tcomp/infoPage?u8=1&oid=OR%3Awt.doc.WTDocument%3A1159279\" target=\"_blank\">STA : 00.4018.002.XXX</a> for the same supplier and same part revision for the following parts: 004018003000, A";

const input1 = "The following parts will not reach Production unless they are also released on an ECN. They are not currently on an ECN: <br> <br><table style=\"border: 1px solid black; width: 100%;border-collapse: collapse;\"><tr><th style=\"border: 1px solid black;\">Number</th><th style=\"border: 1px solid black;\">Name</th><th style=\"border: 1px solid black;\">Version</th></tr><tr><td style=\"border: 1px solid black;\"><meta 00.4018.004.000 /><a href=\"http://ajl-w11-wc12.sram.com/Windchill/app/#ptc1/tcomp/infoPage?u8=1&oid=OR%3Awt.part.WTPart%3A1128209\" target=\"_blank\">00.4018.004.000</a></td><td style=\"border: 1px solid black;\">FS-PIKE-ULT-C1 4551 AB</td><td style=\"border: 1px solid black;\">A.110</td></tr></table><br> - Select Yes to ignore this warning and create the GQA(s)<br> - Select No to cancel creating GQA(s)";

func FindUniqueChars()  {
    var unique0 = "";
    var unique1 = "";

    var working0 = strings.Clone(input0);
    var working1 = strings.Clone(input1);
    for _, char := range working0 {
        working0 = strings.ReplaceAll(working0, string(char), "")
        working1 = strings.ReplaceAll(working1, string(char), "")
    }
    unique1 = strings.Clone(working1)

    working0 = strings.Clone(input0);
    working1 = strings.Clone(input1);

    for _, char := range working1 {
        working0 = strings.ReplaceAll(working0, string(char), "")
        working1 = strings.ReplaceAll(working1, string(char), "")
    }
    unique0 = strings.Clone(working0)

    println("Unique chars in Input 0: " + unique0)
    println("Unique chars in Input 1: " + unique1)
}
