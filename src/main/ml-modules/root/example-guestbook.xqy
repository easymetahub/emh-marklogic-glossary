(:
 : Sample Guestbook Web App, just visit /guestbook on a XQRS server
 : You can delete this along with guestbook.css
 :)
xquery version "1.0-ml";

module namespace  gb     = "http://www.xmllondon.com/guestbook";
declare namespace rest   = "http://exquery.org/ns/restxq";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";

declare
  %rest:path("/guestbook")
  %rest:GET
  %output:method("html")
function view-guestbook() {
  get-html()
};

declare
  %rest:path("/guestbook")
  %rest:form-param-1("name", "{$name}", "Unknown Author")
  %rest:form-param-2("message", "{$message}", "No message")
  %rest:POST
  %xdmp:update
  %output:method("html")
function sign-guestbook($name as xs:string, $message as xs:string) {
  xdmp:invoke-function(
    function() {
      xdmp:document-insert(
        "/" || sem:uuid-string() || ".xml",
        <guestbook-entry>
          <name>{$name}</name>
          <message>{$message}</message>
          <timestamp>{fn:current-dateTime()}</timestamp>
        </guestbook-entry>
      )
    },
    <options xmlns="xdmp:eval">
      <isolation>different-transaction</isolation>
    </options>
  ),
  get-html()
};

declare function get-html() {
  <html>
    <head>
      <link rel="stylesheet" type="text/css" href="guestbook.css"/>
      <title>My Guestbook</title>
    </head>
    <body>
      <h1>My Guestbook</h1>
      <p>Please sign the guest book</p>
      <form id="guestbook" method="POST" action="/guestbook">
        <table>
          <tr>
            <td><label for="name">Your Name</label></td>
            <td><input type="text" name="name" id="name" /></td>            
          </tr>
          <tr>
            <td><label for="message">Your Message</label></td>
            <td><textarea name="message" id="message"/></td>
          </tr>
          <tr>
            <td colspan="2">
              <input type="submit" id="submit" value="Sign the guestbook"/>
            </td>
          </tr>
        </table>
        
      </form>
      <hr />
      {
        for $entry in /guestbook-entry
        order by xs:dateTime($entry/timestamp) descending
        return (
          <div class="entry">
            <div class="timestamp">{$entry/timestamp}</div>
            <div class="name">{$entry/name}</div>
            <div class="message">{$entry/message}</div>
          </div>
        )
      }
    </body>
  </html>
};