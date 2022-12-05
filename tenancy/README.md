The context for these files is as follows
They are embedded into the main.tf file upon execution and encoded as base64 into the yaml
The runtime environment ultimately is immediately after the instances are created and will be as root on the instance
since the free tier allows for 1 ampere 4 cores and 2 micro 1 core name your files as `ampere_init.sh`, `mini1_init.sh`, `mini2_init.sh`  
