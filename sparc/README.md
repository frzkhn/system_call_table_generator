
$ cut -c 12- systbls_32.S > e_systbls_32.S /* Revome 1st 12 charactor from every lone in the file */
$ rm systbls_32.S; mv e_systbls_32.S systbls_32.S
$ while read a b c d e ; do echo -e ".long $a\n .long $b\n .long $c\n .long $d\n .long $e\n" ; done < systbls_32.S > e_systbls_32.S

$ cut -c 12- systbls_64.S > e_systbls_64.S /* Revome 1st 12 charactor from every lone in the file */
$ rm systbls_64.S; mv e_systbls_64.S systbls_32.S
$ while read a b c d e ; do echo -e ".long $a\n.long $b\n.long $c\n.long $d\n.long $e" ; done < systbls_64.S > e_systbls_64/x32.S