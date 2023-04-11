GET http://localhost:80
Host: www.static.com

HTTP 200
Content-Type: text/html

[Asserts]
xpath "normalize-space(//head/title)" equals "Static Index"

GET http://localhost:80
Host: advanced.static.com

HTTP 200
Content-Type: text/html

[Asserts]
xpath "normalize-space(//head/title)" equals "Static Index"

GET http://localhost:80/foo
Host: advanced.static.com

HTTP 404
Content-Type: text/html

[Asserts]
xpath "normalize-space(//head/title)" equals "Not Found"


GET http://localhost:80/api/
Host: advanced.static.com
HTTP 200
Content-Type: text/html

[Asserts]
xpath "normalize-space(//head/title)" equals "Static Index"
