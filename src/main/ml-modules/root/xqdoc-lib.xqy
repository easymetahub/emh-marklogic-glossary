xquery version "1.0-ml";

(:~
# Introduction

This module retrieves an xqDoc document based on the query parameter `rs:module`.  
It then transforms that XML document to it's JSON equivalent for displaying
in a Polymer 3 webpage.
@author Loren Cahlander
@version 1.0
@since 1.0
 :)
module namespace xq = "http://xqdoc.org/xqrs/resource/xqdoc";
import module namespace json="http://marklogic.com/xdmp/json" at "/MarkLogic/json/json.xqy";

declare namespace rest = "http://exquery.org/ns/restxq";
declare namespace rapi = "http://marklogic.com/rest-api";
 
declare namespace xqdoc="http://www.xqdoc.org/1.0";

(:~ 
 :  This variable defines the name for the xqDoc collection.
 :  The xqDoc XML for all modules should be stored into the
 :  XML database with this collection value.
 :)
declare variable $xq:XQDOC_COLLECTION as xs:string := "xqdoc"; 

(:~
  Generates the JSON for an xqDoc comment
  @param $comment the xqdoc:comment element
  @author Loren Cahlander
  @version 1.0
  @since 1.0
 :)
declare function xq:comment($comment as node()?) {
  if ($comment) 
  then 
    object-node { 
      "description" : fn:string-join($comment/xqdoc:description/text(), " "),
      "authors": array-node { $comment/xqdoc:author/text() },
      "versions": array-node { $comment/xqdoc:version/text() },
      "params": array-node { $comment/xqdoc:param/text() },
      "errors": array-node { $comment/xqdoc:error/text() },
      "deprecated": array-node { $comment/xqdoc:deprecated/text() },
      "see": array-node { $comment/xqdoc:see/text() },
      "since": array-node { $comment/xqdoc:since/text() },
      "custom" : array-node {
        for $custom in $comment/xqdoc:custom
        return
          object-node {
            "tag" : $custom/@tag/string(),
            "description" : fn:string-join($custom/text())
          }
      } 
    } 
  else fn:false()  
};

(:~
Generate the occurrence string for the xqDoc display

&lt;table border="1" style="border-collapse: collapse;"&gt;
&lt;tr&gt;
&lt;th&gt;Occurrence&lt;/th&gt;
&lt;th&gt;Description&lt;/th&gt;
&lt;/tr&gt;
&lt;tr&gt;&lt;td&gt;?&lt;/td&gt;&lt;td&gt;zero or one&lt;/td&gt;&lt;/tr&gt;
&lt;tr&gt;&lt;td&gt;+&lt;/td&gt;&lt;td&gt;one or more&lt;/td&gt;&lt;/tr&gt;
&lt;tr&gt;&lt;td&gt;*&lt;/td&gt;&lt;td&gt;zero or more&lt;/td&gt;&lt;/tr&gt;
&lt;tr&gt;&lt;td&gt;&lt;/td&gt;&lt;td&gt;exactly one&lt;/td&gt;&lt;/tr&gt;
&lt;/table&gt;

@param $type the data type xqDoc element.
@return The description of the occurrence
 :)
declare function xq:occurrence($type as node()?) 
as xs:string
{
  switch ($type/@occurrence)
    case "+" return
      "one or more"
    case "*" return
      "zero or more"
    case "?" return 
      "zero or one"
    default return
      "exactly one"
};

(:~
  Generates the JSON for the xqDoc functions
  @param $functions
  @param $module-uri The URI of the selected module
  @author Loren Cahlander
  @version 1.0
  @since 1.0
 :)
declare function xq:functions($functions as node()*, $module-uri as xs:string?) {
  for $function in $functions
  let $name := fn:string-join($function/xqdoc:name/text())
  let $function-comment := $function/xqdoc:comment
  order by $name
  return
    object-node {
      "comment" : xq:comment($function-comment), 
      "name" : $name,
      "signature" : fn:string-join($function/xqdoc:signature/text(), " "),
      "annotations" : 
        array-node {
          for $annotation in $function/xqdoc:annotations/xqdoc:annotation
          return
            object-node {
              "name" : xs:string($annotation/@name),
              "literals" : 
                array-node {
                  for $literal in $annotation/xqdoc:literal
                  return xs:string($literal)
                }
            }
        },
      "parameters" : array-node {
                        for $parameter in $function/xqdoc:parameters/xqdoc:parameter
                        let $ptest := '$' || $parameter/xqdoc:name/text()
                        let $param := $function//xqdoc:param[fn:starts-with(., $ptest)]
                        let $pbody := fn:substring(fn:string-join($param/text(), " "), fn:string-length($ptest) + 1)
                        let $description := replace($pbody,'^\s+','')
                        return 
                          object-node {
                            "name" : fn:string-join($parameter/xqdoc:name/text(), " "),
                            "type" : fn:string-join($parameter/xqdoc:type/text(), " "),
                            "occurrence" : xq:occurrence($parameter/xqdoc:type),
                            "description" : $description
                          }
                     },
     "return" : if ($function/xqdoc:return) 
                then 
                  object-node {
                      "type" : 
                          if (fn:string-length(xs:string($function/xqdoc:return/xqdoc:type)) gt 0)
                          then fn:string-join($function/xqdoc:return/xqdoc:type/text(), " ")
                          else "empty-sequence()",
                      "occurrence" : 
                          if (fn:string-length(xs:string($function/xqdoc:return/xqdoc:type)) gt 0)
                          then xq:occurrence($function/xqdoc:return/xqdoc:type)
                          else "",
                      "description" : 
                          if ($function/xqdoc:comment/xqdoc:return)
                          then xs:string($function/xqdoc:comment/xqdoc:return)
                          else ""
                  } 
                else fn:false(),
      "invoked" : 
        array-node { 
          xq:invoked($function/xqdoc:invoked, $module-uri) 
        },
      "refVariables" : 
        array-node { 
          xq:ref-variables($function/xqdoc:ref-variable, $module-uri) 
        },
      "references" : 
        array-node { 
          xq:all-function-references(
              fn:collection($xq:XQDOC_COLLECTION)/xqdoc:xqdoc/xqdoc:functions/xqdoc:function/xqdoc:invoked[xqdoc:uri = $module-uri][xqdoc:name = $name], 
              $module-uri
          ) 
        },
      "body": fn:string-join($function/xqdoc:body/text(), " ")
    }
};

(:~
  Generates the JSON for the xqDoc function calls from within a function or a body
  @param $invokes
  @param $module-uri The URI of the selected module
  @author Loren Cahlander
  @version 1.0
  @since 1.0
 :)
declare function xq:invoked($invokes as node()*, $module-uri as xs:string?) {
  for $uri in fn:distinct-values($invokes/xqdoc:uri/text())
  let $trimmed-uri := 
            if (fn:starts-with($uri, '"')) 
            then fn:substring(fn:substring($uri, 1, fn:string-length($uri) - 1), 2)
            else $uri
  order by $trimmed-uri
  return 
    object-node {
      "uri": $trimmed-uri,
      "functions": 
          array-node {
            for $invoke in $invokes[xqdoc:uri = $uri]
            let $name := $invoke/xqdoc:name/text()
            order by $name
            return
              object-node {
                "uri" : $trimmed-uri,
                "name" : $name,
                "isReachable" : 
                      if (fn:collection($xq:XQDOC_COLLECTION)/xqdoc:xqdoc[xqdoc:module/xqdoc:uri = $trimmed-uri][xqdoc:functions/xqdoc:function/xqdoc:name = $name])
                      then fn:true()
                      else fn:false(),
                "isInternal" :
                      if ($invoke/xqdoc:uri/text() = $module-uri)
                      then fn:true()
                      else fn:false()
              }

          }
    }
};

(:~
  Generates the JSON for the xqDoc variable references from within a function or a body
  @param $references
  @param $module-uri The URI of the selected module
  @author Loren Cahlander
  @version 1.0
  @since 1.0
 :)
declare function xq:ref-variables($references as node()*, $module-uri as xs:string?) {
  for $uri in fn:distinct-values($references/xqdoc:uri/text())
  let $trimmed-uri := 
            if (fn:starts-with($uri, '"')) 
            then fn:substring(fn:substring($uri, 1, fn:string-length($uri) - 1), 2)
            else $uri
  order by $trimmed-uri
  return 
    object-node {
      "uri": $uri,
      "variables": 
          array-node {
            for $reference in $references[xqdoc:uri = $uri]
            let $name := $reference/xqdoc:name/text()
            order by $name
            return
              object-node {
                "uri" : $trimmed-uri,
                "name" : $name,
                "isReachable" : 
                      if (fn:collection($xq:XQDOC_COLLECTION)/xqdoc:xqdoc[xqdoc:module/xqdoc:uri = $trimmed-uri][xqdoc:variables/xqdoc:variable/xqdoc:name = $name])
                      then fn:true()
                      else fn:false(),
                "isInternal" :
                      if ($reference/xqdoc:uri/text() = $module-uri)
                      then fn:true()
                      else fn:false()
              }

          }
    }
};

(:~
  @param $references
  @param $module-uri The URI of the selected module
  @author Loren Cahlander
  @version 1.0
  @since 1.0
 :)
declare function xq:all-variable-references($references as node()*, $module-uri as xs:string?) {
  let $uris := fn:distinct-values( 
      for $reference in $references
      let $uri := $reference/fn:root()//xqdoc:module/xqdoc:uri/text()
      order by $uri
      return $uri
  )
  return
    for $uri in $uris
    return 
      object-node {
        "uri": $uri,
        "functions": 
          array-node {
            for $reference in $references
            let $testuri := $reference/fn:root()//xqdoc:module/xqdoc:uri/text()
            let $name := $reference/../xqdoc:name/text()
            order by $name
            return 
              if ($testuri = $uri)
              then
                object-node { 
                  "name" : $name, 
                  "uri": $uri,
                  "isReachable" : 
                        if (fn:collection($xq:XQDOC_COLLECTION)/xqdoc:xqdoc[xqdoc:module/xqdoc:uri = $uri][xqdoc:functions/xqdoc:function/xqdoc:name = $name])
                        then fn:true()
                        else fn:false(),
                  "isInternal" : 
                    if ($uri = $module-uri) 
                    then fn:true() 
                    else fn:false()
                }            
              else ()
          }

      }
};

(:~
  @param $references
  @param $module-uri The URI of the selected module
  @author Loren Cahlander
  @version 1.0
  @since 1.0
 :)
declare function xq:all-function-references($references as node()*, $module-uri as xs:string?) {
  let $uris := fn:distinct-values( 
      for $reference in $references
      let $uri := $reference/fn:root()//xqdoc:module/xqdoc:uri/text()
      order by $uri
      return $uri
  )
  return
    for $uri in $uris
    return 
      object-node {
        "uri": $uri,
        "functions": 
          array-node {
            for $reference in $references
            let $testuri := $reference/fn:root()//xqdoc:module/xqdoc:uri/text()
            let $name := $reference/../xqdoc:name/text()
            order by $name
            return 
              if ($testuri = $uri)
              then
                object-node { 
                  "name" : $name, 
                  "uri": $uri,
                  "isReachable" : 
                        if (fn:collection($xq:XQDOC_COLLECTION)/xqdoc:xqdoc[xqdoc:module/xqdoc:uri = $uri][xqdoc:functions/xqdoc:function/xqdoc:name = $name])
                        then fn:true()
                        else fn:false(),
                  "isInternal" : 
                    if ($uri = $module-uri) 
                    then fn:true() 
                    else fn:false()
                }            
              else ()
          }

      }
};

(:~
  @param $variables A sequence of the xqdoc:variable elements
  @param $module-uri The URI of the selected module
  @author Loren Cahlander
  @version 1.0
  @since 1.0
 :)
declare function xq:variables($variables as node()*, $module-uri as xs:string?) {
  for $variable in $variables
  let $uri := $variable/xqdoc:uri/text()
  let $name := $variable/xqdoc:name/text()
  return
    object-node {
      "comment" : xq:comment($variable/xqdoc:comment),
      "uri" : $uri,
      "name" : $name,
      "references" : 
        array-node { 
          xq:all-variable-references(
            fn:collection($xq:XQDOC_COLLECTION)/xqdoc:xqdoc/xqdoc:functions/xqdoc:function/xqdoc:ref-variable[xqdoc:uri = $uri][xqdoc:name = $name], 
            $module-uri
          ) 
        }
    }
};

(:~
  @param $imports A sequence of the xqdoc:import elements
  @author Loren Cahlander
  @version 1.0
  @since 1.0
 :)
declare function xq:imports($imports as node()*) {
  for $import in $imports
  let $uri := $import/xqdoc:uri/text()
  return
    object-node {
      "comment" : xq:comment($import/xqdoc:comment),
      "uri" : fn:substring(fn:substring($uri, 1, fn:string-length($uri) - 1), 2),
      "type" : xs:string($import/@type)
    }
};

(:~
  Gets the xqDoc of a module as JSON
  @param $module The URI of the module to display
  @author Loren Cahlander
  @version 1.0
  @since 1.0
 :)
declare 
  %rest:GET
  %rest:path("/get-xqdoc")
  %rest:query-param-1('module', '{$module}')
  %rest:produces("application/json")
function xq:get(
  $module as xs:string?
  ) 
{
  let $_ := xdmp:log("GET called")

  let $doc := (
          fn:collection($xq:XQDOC_COLLECTION)/xqdoc:xqdoc[xqdoc:module/xqdoc:uri = $module], 
          fn:doc($module)/xqdoc:xqdoc
          )[1]
  let $module-comment := $doc/xqdoc:module/xqdoc:comment
  return 
    document { 
      object-node {  
        "modules" : object-node {
            "libraries" : array-node {
              for $uri in fn:collection($xq:XQDOC_COLLECTION)/xqdoc:xqdoc/xqdoc:module[@type = "library"]/xqdoc:uri/text()
              order by $uri
              return
                object-node {
                  "uri" : $uri,
                  "selected" : if ($uri = $module) then fn:true() else fn:false()
                }
            },
            "main" : array-node {
              for $module in fn:collection($xq:XQDOC_COLLECTION)/xqdoc:xqdoc[xqdoc:module/@type = "main"]
              let  $uri := xs:string(fn:base-uri($module))
              order by $uri
              return
                object-node {
                  "uri" : $uri,
                  "selected" : if ($uri = $module) then fn:true() else fn:false()
                }
            }
          },
        "response" : if ($doc) then object-node {
          "control" : object-node {
                        "date" : $doc/xqdoc:control/xqdoc:date/text(),
                        "version" : $doc/xqdoc:control/xqdoc:version/text()
                      },
          "comment" : xq:comment($module-comment),
          "uri": $module,
          "name" : 
            if ($doc/xqdoc:module/xqdoc:name) 
            then $doc/xqdoc:module/xqdoc:name/text() 
            else fn:false(),
          "invoked" : 
            array-node { 
              xq:invoked($doc/xqdoc:module/xqdoc:invoked, $module) 
            },
          "refVariables" : 
            array-node { 
              xq:ref-variables($doc/xqdoc:module/xqdoc:ref-variable, $module) 
            },
          "variables" : 
            if ($doc/xqdoc:variables) 
            then 
              array-node {
               xq:variables($doc/xqdoc:variables/xqdoc:variable, $doc/xqdoc:module/xqdoc:uri/text()) 
             } 
            else fn:false(),
          "imports" : 
            if ($doc/xqdoc:imports) 
            then 
              array-node { 
                xq:imports($doc/xqdoc:imports/xqdoc:import) 
              } 
            else fn:false(),
          "functions" : 
            if ($doc/xqdoc:functions) 
            then 
              array-node { 
                xq:functions($doc/xqdoc:functions/xqdoc:function, $doc/xqdoc:module/xqdoc:uri/text()) 
              } 
            else fn:false(),
          "body": fn:string-join($doc/xqdoc:module/xqdoc:body/text(), " ")
        } else fn:false()
      } 
    }
};
