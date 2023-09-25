# Container ssh


Directory images/ssh contains a minimal training ground for generating and running a docker image with alpine 
and a secure shell entry into the system.

### Cheat Sheet ###

* Adjust file ```PARAMETERS.sh```
* ```prepare.sh```  prepares a universal public, private key pair that we shall use for logging in into EVERY container running this image
* ```generate.sh```  generate the container
* ```run.sh```  run the container
* ```postpare.sh```  prepare the local ssh installation for public key logon
* ```ssh -i login-key -p 2222 cap@localhost```

#### Running an Image as a Container ####
