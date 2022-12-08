The context for these files is as follows
They are embedded into the main.tf file upon execution and encoded as base64 into the yaml
The runtime environment ultimately is immediately after the instances are created and will be as root on the instance
since the free tier allows for 1 ampere 4 cores and 2 micro 1 core name your files as `ampere_init.sh`, `mini1_init.sh`, `mini2_init.sh`  



The file names should match tenancys and the files within should `contain` host names. If there are multiple files `containing` host names they will be concatinated in alpha-numeric order.

if your directory looks like this
```
head_ampere_mini-1.sh
mini-2.sh
script_ampere.sh
tail_ampere.sh
tail_mini-1.sh
```
Example: for ampere: head_ampere_mini-1.sh,script_ampere.sh,tail_ampere.sh
Example2: for mini-1: head_ampere_mini-1, tail_mini-1.sh
Example: for mini-2: mini-2.sh
