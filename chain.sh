#!/bin/bash
rm *.p12 2> /dev/null
rm *.cer 2> /dev/null

# generate private keys (for root_ca and intermediate_ca)

keytool -genkeypair -alias root_ca -dname cn=root_ca -validity 3650 -keyalg RSA -keysize 4096 -ext bc:c -keystore root_ca.p12 -keypass 12345678 -storepass 12345678
keytool -genkeypair -alias intermediate_ca -dname cn=intermediate_ca -validity 3650 -keyalg RSA -keysize 4096 -ext bc:c -keystore intermediate_ca.p12 -keypass 12345678 -storepass 12345678

# generate root_ca certificate
keytool -exportcert -rfc -keystore root_ca.p12 -alias root_ca -storepass 12345678 > root_ca.cer

# generate a certificate for intermediate_ca signed by root_ca (root_ca -> intermediate_ca)
keytool -keystore intermediate_ca.p12 -storepass 12345678 -certreq -alias intermediate_ca \
| keytool -keystore root_ca.p12 -storepass 12345678 -gencert -alias root_ca -validity 3650 -ext bc=0 -ext san=dns:intermediate-ca -rfc > intermediate_ca.cer

# import intermediate_ca cert chain into intermediate_ca.p12
keytool -keystore intermediate_ca.p12 -storepass 12345678 -importcert -trustcacerts -noprompt -alias root_ca -file root_ca.cer
keytool -keystore intermediate_ca.p12 -storepass 12345678 -importcert -alias intermediate_ca -file intermediate_ca.cer

# generate private keys (for server)

keytool -genkeypair -alias server -dname cn=server -validity 3650 -keyalg RSA -keysize 4096 -keystore my-keystore.p12 -keypass 12345678 -storepass 12345678

# generate a certificate for server signed by intermediate_ca (root_ca -> intermediate_ca -> server)

keytool -keystore my-keystore.p12 -storepass 12345678 -certreq -alias server \
| keytool -keystore intermediate_ca.p12 -storepass 12345678 -gencert -alias intermediate_ca -validity 3650 -ext ku:c=dig,keyEnc -ext san=dns:localhost -ext eku=sa,ca -rfc > server.cer

# import server cert chain into my-keystore.p12

keytool -keystore my-keystore.p12 -storepass 12345678 -importcert -trustcacerts -noprompt -alias root_ca -file root_ca.cer
# keytool -keystore my-keystore.p12 -storepass 12345678 -importcert -alias ca -file ca.cer
keytool -keystore my-keystore.p12 -storepass 12345678 -importcert -alias server -file server.cer

# import server cert chain into my-truststore.p12

keytool -keystore my-truststore.p12 -storepass 12345678 -importcert -trustcacerts -noprompt -alias root_ca -file root_ca.cer
keytool -keystore my-truststore.p12 -storepass 12345678 -importcert -alias intermediate_ca -file intermediate_ca.cer
# keytool -keystore my-truststore.p12 -storepass 12345678 -importcert -alias server -file server.cer
