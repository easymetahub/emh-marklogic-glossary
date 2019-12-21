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
 : Module Overview: This module handles the search from the server.
 :
 :)
(:~
 : This module handles the search of the server.
 :
 : @author Loren Cahlander
 : @since October 25, 2018
 : @version 1.0
 :)
module namespace emh-search = "http://www.easymetahub.com/xqrs/search";

import module namespace search = "http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";
import module namespace emhjson="http://easymetahub.com/emh-accelerator/library/json" at "emh-json.xqm";
import module namespace custom="http://easymetahub.com/emh-accelerator/library/custom" at "custom/custom.xqm";

declare namespace rest = "http://exquery.org/ns/restxq";
declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace skos="http://www.w3.org/2008/05/skos#";
declare namespace rdfs="http://www.w3.org/2000/01/rdf-schema#";
declare namespace dc="http://purl.org/dc/elements/1.1/";

declare option xdmp:output "method=json";

(:~
 : This method allows for the odering of facets showing the selected snippets first
 :
 : @param $facets          The facets from the search result
 : @param $return-selected The flag to determine if the facet should be returned if the facet has a selected value.
 : @param $qtext           The 'search:qtext' of the search results to find the selected facet value(s)
 :)
declare function emh-search:facets-by-selection($facets as node()*, $return-selected as xs:boolean, $qtext as xs:string)
{
    for $facet in $facets[search:facet-value]
    let $selected := 
        for $value in $facet/search:facet-value
        return if (fn:contains($qtext, emhjson:facet-text($facet/@name/string(), $value/@name/string()))) then $value else ()
    return
        if (fn:not($selected))
        then 
            if ($return-selected) then () else $facet
        else
            if ($return-selected) then $facet else ()
};


(:~
Search the metadata
@param $q           The query string
@param $start       The offset into the search results where the response begins
@param $pagelength  The number of result items to return from the start position
@param $facets
This is a string containing the selected facets for the query and each facet is separtated by a double-tilde '~~'.

A facet is represented by the facet name and the value separated by a colon ':'
@param $debug       If this is set to true, then the raw search results are returned.
 :)
declare
  %rest:path("/search")
  %rest:query-param-1('q', '{$q}', '*')
  %rest:query-param-2('start', '{$start}', '1')
  %rest:query-param-3('pagelength', '{$pagelength}', '10')
  %rest:query-param-4('facets', '{$facets}', '')
  %rest:query-param-5('debug', '{$debug}')
  %rest:produces("application/json")
function emh-search:perform-search(
  $q as xs:string,
  $start as xs:integer?,
  $pagelength as xs:integer?,
  $facets as xs:string?,
  $debug as xs:boolean?) {
	let $total-count := fn:count(fn:collection($custom:data-collection)//skos:Concept)
	let $facets-param := fn:tokenize($facets, "~~")
	let $end := $start + $pagelength - 1

	(: If there isn't a search string, then return all possible results :)
	let $search-input :=
	    fn:string-join(
	        (
	            ($q, "*")[1],
	            $facets-param
	        ), 
	        " "
	    )

	let $search-results := search:search($search-input, custom:search-options(), $start, $pagelength) 

	let $qtext := $search-results/search:qtext/text()

	let $selected-facets := 
	    for $facet in emh-search:facets-by-selection($search-results/search:facet, fn:true(), $qtext)
	    return custom:facet-object($facet, $qtext)

	let $unselected-facets := 
	    for $facet in emh-search:facets-by-selection($search-results/search:facet, fn:false(), $qtext)
	    return custom:facet-object($facet, $qtext)


	let $results := 
	    for $result in $search-results//search:result
	    return
	        custom:result-object($result, if ($q) then fn:true() else fn:false())

	        
	return
	    if ($debug)
	    then $search-results
	    else
	        object-node {
	            "total" : $search-results/@total/number(),
	            "available" : $total-count,
	            "facets" : array-node { ($selected-facets, $unselected-facets) },
	            "results" : array-node { $results }
	        }
};

(:~
List the glossaries
 :)
declare
  %rest:path("/glossaries")
  %rest:produces("application/json")
function emh-search:list-glossaries() {
	custom:glossaries()
};

(:~
List the glossaries
 :)
declare
  %rest:path("/delete")
  %rest:query-param-1('glossary', '{$glossary}', '*')
  %rest:produces("application/json")
  %xdmp:update
function emh-search:delete-glossary($glossary as xs:string) {
	let $deleted := xdmp:collection-delete("glossary-" || $glossary)
	return
	object-node { "success" : fn:true() }
};
