varnish backend side cache


#
# CDN backend varnish server
# closest to the backend
# fetches with nginx on localhost
#
vcl 4.0;

backend default {
    .host = "127.0.0.1";
    .port = "81";
}



sub vcl_recv {

    if (req.url ~ "^/varnishping") {
        return (synth(700, "Ping"));
    }

    unset req.http.cookie;
    return (hash);
}

sub vcl_backend_response {

    unset beresp.http.cache-control;
    unset beresp.http.expires;

    set beresp.ttl = 1h;
    set beresp.grace = 6h;
}

sub vcl_deliver {

    set resp.http.backendvarnish = "lol";

    if (obj.hits > 0) {
        set resp.http.j-back-cache = "hit";
    } else {
        set resp.http.j-back-cache = "miss";
    }

}

sub vcl_synth {

    #set resp.http.Retry-After = "5";
    if (resp.status == 700) {
        set resp.status = 200;
        set resp.reason = "OK";
        set resp.http.Content-Type = "text/plain;";
        synthetic( {"Pong"} );
        return (deliver);
    }
    return (deliver);
}