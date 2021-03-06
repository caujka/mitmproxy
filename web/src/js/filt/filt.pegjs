// PEG.js filter rules - see http://pegjs.majda.cz/online

{
function or(first, second) {
    // Add explicit function names to ease debugging.
    function orFilter() {
        return first.apply(this, arguments) || second.apply(this, arguments);
    }
    orFilter.desc = first.desc + " or " + second.desc;
    return orFilter;
}
function and(first, second) {
    function andFilter() {
        return first.apply(this, arguments) && second.apply(this, arguments);
    }
    andFilter.desc = first.desc + " and " + second.desc;
    return andFilter;
}
function not(expr) {
    function notFilter() {
        return !expr.apply(this, arguments);
    }
    notFilter.desc = "not " + expr.desc;
    return notFilter;
}
function binding(expr) {
    function bindingFilter() {
        return expr.apply(this, arguments);
    }
    bindingFilter.desc = "(" + expr.desc + ")";
    return bindingFilter;
}
function trueFilter(flow) {
    return true;
}
trueFilter.desc = "true";
function falseFilter(flow) {
    return false;
}
falseFilter.desc = "false";

var ASSET_TYPES = [
    new RegExp("text/javascript"),
    new RegExp("application/x-javascript"),
    new RegExp("application/javascript"),
    new RegExp("text/css"),
    new RegExp("image/.*"),
    new RegExp("application/x-shockwave-flash")
];
function assetFilter(flow) {
    if (flow.response) {
        var ct = ResponseUtils.getContentType(flow.response);
        var i = ASSET_TYPES.length;
        while (i--) {
            if (ASSET_TYPES[i].test(ct)) {
                return true;
            }
        }
    }
    return false;
}
assetFilter.desc = "is asset";
function responseCode(code){
    function responseCodeFilter(flow){
        return flow.response && flow.response.code === code;
    }
    responseCodeFilter.desc = "resp. code is " + code;
    return responseCodeFilter;
}
function domain(regex){
    regex = new RegExp(regex, "i");
    function domainFilter(flow){
        return flow.request && regex.test(flow.request.host);
    }
    domainFilter.desc = "domain matches " + regex;
    return domainFilter;
}
function errorFilter(flow){
    return !!flow.error;
}
errorFilter.desc = "has error";
function header(regex){
    regex = new RegExp(regex, "i");
    function headerFilter(flow){
        return (
            (flow.request && RequestUtils.match_header(flow.request, regex))
            ||
            (flow.response && ResponseUtils.match_header(flow.response, regex))
        );
    }
    headerFilter.desc = "header matches " + regex;
    return headerFilter;
}
function requestHeader(regex){
    regex = new RegExp(regex, "i");
    function requestHeaderFilter(flow){
        return (flow.request && RequestUtils.match_header(flow.request, regex));
    }
    requestHeaderFilter.desc = "req. header matches " + regex;
    return requestHeaderFilter;
}
function responseHeader(regex){
    regex = new RegExp(regex, "i");
    function responseHeaderFilter(flow){
        return (flow.response && ResponseUtils.match_header(flow.response, regex));
    }
    responseHeaderFilter.desc = "resp. header matches " + regex;
    return responseHeaderFilter;
}
function method(regex){
    regex = new RegExp(regex, "i");
    function methodFilter(flow){
        return flow.request && regex.test(flow.request.method);
    }
    methodFilter.desc = "method matches " + regex;
    return methodFilter;
}
function noResponseFilter(flow){
    return flow.request && !flow.response;
}
noResponseFilter.desc = "has no response";
function responseFilter(flow){
    return !!flow.response;
}
responseFilter.desc = "has response";

function contentType(regex){
    regex = new RegExp(regex, "i");
    function contentTypeFilter(flow){
        return (
            (flow.request && regex.test(RequestUtils.getContentType(flow.request)))
            ||
            (flow.response && regex.test(ResponseUtils.getContentType(flow.response)))
        );
    }
    contentTypeFilter.desc = "content type matches " + regex;
    return contentTypeFilter;
}
function requestContentType(regex){
    regex = new RegExp(regex, "i");
    function requestContentTypeFilter(flow){
        return flow.request && regex.test(RequestUtils.getContentType(flow.request));
    }
    requestContentTypeFilter.desc = "req. content type matches " + regex;
    return requestContentTypeFilter;
}
function responseContentType(regex){
    regex = new RegExp(regex, "i");
    function responseContentTypeFilter(flow){
        return flow.response && regex.test(ResponseUtils.getContentType(flow.response));
    }
    responseContentTypeFilter.desc = "resp. content type matches " + regex;
    return responseContentTypeFilter;
}
function url(regex){
    regex = new RegExp(regex, "i");
    function urlFilter(flow){
        return flow.request && regex.test(RequestUtils.pretty_url(flow.request));
    }
    urlFilter.desc = "url matches " + regex;
    return urlFilter;
}
}

start "filter expression"
  = __ orExpr:OrExpr __ { return orExpr; }
  / {return trueFilter; }

ws "whitespace" = [ \t\n\r]
cc "control character" = [|&!()~"]
__ "optional whitespace" = ws*

OrExpr
  = first:AndExpr __ "|" __ second:OrExpr 
    { return or(first, second); }
  / AndExpr

AndExpr
  = first:NotExpr __ "&" __ second:AndExpr 
    { return and(first, second); }
  / first:NotExpr ws+ second:AndExpr 
    { return and(first, second); }
  / NotExpr

NotExpr
  = "!" __ expr:NotExpr 
    { return not(expr); }
  / BindingExpr

BindingExpr
  = "(" __ expr:OrExpr __ ")" 
    { return binding(expr); }
  / Expr

Expr
  = NullaryExpr
  / UnaryExpr

NullaryExpr
  = BooleanLiteral
  / "~a" { return assetFilter; }
  / "~e" { return errorFilter; }
  / "~q" { return noResponseFilter; }
  / "~s" { return responseFilter; }


BooleanLiteral
  = "true" { return trueFilter; }
  / "false" { return falseFilter; }

UnaryExpr
  = "~c"  ws+ s:IntegerLiteral { return responseCode(s); }
  / "~d"  ws+ s:StringLiteral { return domain(s); }
  / "~h"  ws+ s:StringLiteral { return header(s); }
  / "~hq" ws+ s:StringLiteral { return requestHeader(s); }
  / "~hs" ws+ s:StringLiteral { return responseHeader(s); }
  / "~m"  ws+ s:StringLiteral { return method(s); }
  / "~t"  ws+ s:StringLiteral { return contentType(s); }
  / "~tq" ws+ s:StringLiteral { return requestContentType(s); }
  / "~ts" ws+ s:StringLiteral { return responseContentType(s); }
  / "~u"  ws+ s:StringLiteral { return url(s); }
  / s:StringLiteral { return url(s); }

IntegerLiteral "integer"
  = ['"]? digits:[0-9]+ ['"]? { return parseInt(digits.join(""), 10); }

StringLiteral "string"
  = '"' chars:DoubleStringChar* '"' { return chars.join(""); }
  / "'" chars:SingleStringChar* "'" { return chars.join(""); }
  / !cc chars:UnquotedStringChar+ { return chars.join(""); }

DoubleStringChar
  = !["\\] char:. { return char; }
  / "\\" char:EscapeSequence { return char; }

SingleStringChar
  = !['\\] char:. { return char; }
  / "\\" char:EscapeSequence { return char; }

UnquotedStringChar
  = !ws char:. { return char; }

EscapeSequence
  = ['"\\]
  / "n" { return "\n"; }
  / "r" { return "\r"; }
  / "t" { return "\t"; }