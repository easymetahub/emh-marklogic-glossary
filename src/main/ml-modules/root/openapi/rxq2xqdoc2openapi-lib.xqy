xquery version "1.0-ml";

(:~
 :)
module namespace rxq2openapi="http://xqdoc.org/library/rxq/xqdoc/openapi";

import module namespace json = "http://marklogic.com/xdmp/json"
    at "/MarkLogic/json/json.xqy";
    
declare default element namespace "http://marklogic.com/xdmp/json/basic";
declare namespace xqdoc="http://www.xqdoc.org/1.0";

(:~
 :)
declare variable $rxq2openapi:service-names := ("rxq:GET", "rxq:HEAD", "rxq:PUT", "rxq:POST", "rxq:DELETE", "rxq:OPTIONS", "rxq:PATCH");


(:~
 :)
declare function rxq2openapi:get-parameter-description($function as node(), $literal as node())
as xs:string
{
  let $param-name := fn:substring-after(fn:substring-before(xs:string($literal), "}"), "{")
  return rxq2openapi:get-string-parameter-description($function, $param-name)
};

(:~
 :)
declare function rxq2openapi:get-string-parameter-description($function as node(), $param-name as xs:string)
as xs:string
{
  let $param := $function/xqdoc:comment/xqdoc:param[fn:starts-with(., $param-name)]/text()
  
  return 
    if ($param)
    then replace(fn:substring-after($param, $param-name),'^\s+','')
    else ""
};

(:~
 :)
declare function rxq2openapi:schema-object($type as node())
as map:map
{
    let $schema-object := map:map()
    let $_type := map:put($schema-object, "type", $type/text())
    let $_card := 
            switch ($type/@occurrence/string())
            case "*" return (map:put($schema-object, "minItems", 0))
            case "+" return (map:put($schema-object, "minItems", 1))
            case "?" return (map:put($schema-object, "minItems", 0), map:put($schema-object, "maxItems", 1))
            default return (map:put($schema-object, "minItems", 1), map:put($schema-object, "maxItems", 1))
    return $schema-object
};

(:~
 :)
declare function rxq2openapi:parameter-object($name as xs:string, $in as xs:string, $description as xs:string?, $parameters as node()?)
as map:map
{
    let $obj := map:map()
    let $_name := map:put($obj, "name", $name)
    let $_in   := map:put($obj, "in", $in)
    let $_desc := map:put($obj, "description", $description)
    let $_param := 
              if ($parameters/xqdoc:parameter[xqdoc:name = $name][xqdoc:type])
              then map:put($obj, "schema", rxq2openapi:schema-object($parameters/xqdoc:parameter[xqdoc:name = $name]/xqdoc:type))
              else ()
    return $obj
};

(:~
 :)
declare function rxq2openapi:service-object($function as node()?, $path as xs:string) 
as map:map?
{
  if ($function)
  then 
    let $service-object := map:map()
    let $path-parameters := 
            for $token in fn:tokenize($path, "[{{}}]")[fn:starts-with(., "$")]
            return if (fn:contains($token, "=")) then fn:substring-before($token, "=") else $token

    let $responses-object := map:map()
    let $_ := (
        for $producer in $function//xqdoc:annotation[fn:starts-with(@name, "rxq:produces")]
        return 
            for $literal in $producer/xqdoc:literal
            return map:put($responses-object, xs:string($literal), map:map())
    )

    let $parameters-array := json:array()
    let $_ := (
                for $param in $function//xqdoc:annotation[fn:starts-with(@name, "rxq:query-param")]
                let $name := $param/xqdoc:literal[1]/text()
                let $description := rxq2openapi:get-parameter-description($function, $param/xqdoc:literal[2])
                let $obj := rxq2openapi:parameter-object($name, "query", $description, $function//xqdoc:parameters)
                let $_push := json:array-push($parameters-array, $obj)
                return (),
                for $param in $function//xqdoc:annotation[fn:starts-with(@name, "rxq:header-param")]
                let $name := $param/xqdoc:literal[1]/text()
                let $description := rxq2openapi:get-parameter-description($function, $param/xqdoc:literal[2])
                let $obj := rxq2openapi:parameter-object($name, "header", $description, $function//xqdoc:parameters)
                let $_push := json:array-push($parameters-array, $obj)
                return (),
                for $param in $function//xqdoc:annotation[fn:starts-with(@name, "rxq:cookie-param")]
                let $name := $param/xqdoc:literal[1]/text()
                let $description := rxq2openapi:get-parameter-description($function, $param/xqdoc:literal[2])
                let $obj := rxq2openapi:parameter-object($name, "cookie", $description, $function//xqdoc:parameters)
                let $_push := json:array-push($parameters-array, $obj)
                return (),
                for $param in $path-parameters
                let $name := fn:substring($param, 2)
                let $description := rxq2openapi:get-string-parameter-description($function, $param)
                let $obj := rxq2openapi:parameter-object($name, "path", $description, $function//xqdoc:parameters)
                let $_push := json:array-push($parameters-array, $obj)
                return ()
    )
    let $_ := (
            map:put($service-object, "description", fn:string-join($function/xqdoc:comment/xqdoc:description/text())),
            map:put($service-object, "responses", $responses-object),
            if (json:array-size($parameters-array) gt 0) then map:put($service-object, "parameters", $parameters-array) else ()
    )

    return $service-object
  else ()
};

(:~
 :)
declare function rxq2openapi:process-rxq-to-xqDoc-to-OpenAPI()
as map:map
{
let $paths-object := map:map()

let $functions := fn:collection("xqdoc")/xqdoc:xqdoc/xqdoc:functions/xqdoc:function[xqdoc:annotations/xqdoc:annotation[@name = "rxq:path"]] 
let $path-names := 
    for $path in fn:distinct-values($functions//xqdoc:annotation[@name = "rxq:path"]/xqdoc:literal[1]/text())
    order by $path
    return $path

let $paths := 
    for $path in $path-names    
    let $path-functions := $functions[xqdoc:annotations/xqdoc:annotation[@name = "rxq:path"][xqdoc:literal = $path]]
    let $path-object := map:map()
    let $services := (
          if (fn:not($path-functions[xqdoc:annotations/xqdoc:annotation[@name = $rxq2openapi:service-names]]))
          then 
            let $function := $path-functions[xqdoc:annotations/xqdoc:annotation[fn:not(@name = $rxq2openapi:service-names)]][1]
            let $service-object := rxq2openapi:service-object($function, $path)
            return 
              if (fn:exists($service-object))
              then map:put($path-object, "get", $service-object)
              else ()
          else (),
          for $service-name in $rxq2openapi:service-names
          let $function := $path-functions[xqdoc:annotations/xqdoc:annotation[@name = $service-name]][1]
          let $service-object := rxq2openapi:service-object($function, $path)
          return 
            if (fn:exists($service-object))
            then map:put($path-object, fn:lower-case(fn:substring-after($service-name, ":")), $service-object)
            else ()
    )
    return map:put($paths-object, $path, $path-object)
return $paths-object
};
