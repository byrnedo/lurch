GET https://localhost:443
Host: www.tls.com

[Options]
insecure: true

HTTP 200

GET https://le.tls.com:443/
[Options]
insecure: true

HTTP 200

[Asserts]
# add back once v3 is out
#certificate "Subject" == "C=US, ST=Denial, L=Springfield, O=Dis, CN=localhost"
#certificate "Issuer" == "C=US, ST=Denial, L=Springfield, O=Dis, CN=localhost"



