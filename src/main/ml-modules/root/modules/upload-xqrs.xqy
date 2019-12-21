xquery version "1.0-ml";
(:
 : Module Name: Search Module
 :
 : Module Version: 1.0
 :
 : Date: 10/25/2018
 :
 : Copyright (c) 2018. EasyMetaHub, LLC
 :
 : Proprietary
 : Extensions: MarkLogic
 :
 : XQuery
 : Specification March 2017
 :
 : Module Overview: This module handles the upload from the server.
 :
 :)
(:~
 : This module handles the upload of the server.
 :
 : @author Loren Cahlander
 : @since October 25, 2018
 : @version 1.0
 :)
module namespace emh-upload = "http://www.easymetahub.com/xqrs/upload";

import module namespace custom="http://easymetahub.com/emh-accelerator/library/custom" at "custom/custom.xqm";

declare namespace rest = "http://exquery.org/ns/restxq";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

(:~
Upload zip file to the server

@param $files 
## The uploaded files

* The map's keys represent the filenames of each file uploaded
* The map's values are themselves maps too, let's call this an "entry map"
* The entry map contains two keys, a content-type and a body
* The value for content-type is the Content Type of this particular file
* The value for body is the Content Body of this particular file as a binary() item

 :)
declare
  %rest:path("/upload-all")
  %rest:form-param("my-attachment", "{$files}")
  %output:method("json")
  %xdmp:update
function emh-upload:upload($files as map:map) 
as object-node()
{
    object-node {
        "glossaries" : custom:glossaries(),
        "results" : 
            array-node {
                if (fn:count(map:keys($files)) eq 0)
                then 
                    object-node {
                        "filename" : "none", 
                        "messages" : 
                            array-node { 
                                object-node { 
                                    "type" : "error", 
                                    "message" : "There are no files to process!" 
                                } 
                            } 
                    }
                else
        			for $filename in map:keys($files) (: iterate through files :)
        			let $entry-map as map:map := map:get($files, $filename) (: a map per file :)
        			let $content-type as xs:string? := map:get($entry-map, "content-type")
        			let $body := map:get($entry-map, "body")
                    return
                        custom:process-upload($filename, $body)
            }
    }
};