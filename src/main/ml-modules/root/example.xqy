xquery version "1.0-ml";

module namespace example = "http://www.example.org/example";
declare namespace rest = "http://exquery.org/ns/restxq";

declare
  %rest:path("/hello-world")
function hello-world() {
  "Hello World"
};

declare
  %rest:path("/echo/{$param}")
function echo($param as xs:string) {
  $param
};
