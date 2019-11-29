xquery version "1.0-ml";

(:~
 This module generates the OpenAPI JSON document for the OpenAPI display.
 @author Loren Cahlander
 @version 1.0
 @since 1.0
 @return the OpenAPI JSON document for the OpenAPI display
 @see https://github.com/OAI/OpenAPI-Specification
 @see https://github.com/lcahlander/xqdoc
 :)
 
import module namespace xqrs2openapi="http://xqdoc.org/library/xqrs/xqdoc/openapi" at "xqrs2xqdoc2openapi-lib.xqy";

let $base := fn:doc("/xqDoc/openapi.json")


let $paths-object := 
		xdmp:to-json(xqrs2openapi:process-xqrs-to-xqDoc-to-OpenAPI())

return object-node { 
    "openapi" : "3.0.0", 
    "info" : $base/info, 
    "servers" : array-node { $base/servers }, 
    "paths" : $paths-object, 
    "components" : $base/components
    }
 