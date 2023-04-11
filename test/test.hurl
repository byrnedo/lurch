GET http://localhost:80
Host: does.not-exist.com

HTTP 404
Content-Type: text/html     # Implicit assert on Content-Type Header
[Asserts]                                          # Explicit asserts section

GET http://localhost:80
Host: www.static.com

HTTP 200
Content-Type: text/html

[Asserts]
xpath "normalize-space(//head/title)" equals "Index"

GET http://localhost:80
Host: www.dynamic.com

HTTP 200
Content-Type: text/html

GET http://localhost:80
Host: advanced.static.com

HTTP 200
Content-Type: text/html

[Asserts]
xpath "normalize-space(//head/title)" equals "Index"

GET http://localhost:80/foo
Host: advanced.static.com

HTTP 404
Content-Type: text/html

[Asserts]
xpath "normalize-space(//head/title)" equals "Not Found"
