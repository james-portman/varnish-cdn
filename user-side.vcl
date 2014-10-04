#
# CDN frontend/user side varnish
#
vcl 4.0;

# Default backend definition. Set this to point to your content server.
backend backendvarnish1 {
    .host = "192.168.0.140";
    .port = "6081";
    .probe = {
        .url = "/varnishping";
        .interval = 10s;
        .timeout = 2s;
        .window = 5;
        .threshold = 3;
    }
}
backend backendvarnish2 {
    .host = "192.168.0.140";
    .port = "6081";
    .probe = {
        .url = "/varnishping";
        .interval = 10s;
        .timeout = 2s;
        .window = 5;
        .threshold = 3;
    }
}
backend backendvarnish3 {
    .host = "192.168.0.140";
    .port = "6081";
    .probe = {
        .url = "/varnishping";
        .interval = 10s;
        .timeout = 2s;
        .window = 5;
        .threshold = 3;
    }
}

backend localnginx {
    .host = "127.0.0.1";
    .port = "81";
    .probe = {
        .url = "/varnishping";
        .interval = 10s;
        .timeout = 2s;
        .window = 5;
        .threshold = 3;
    }
}


import directors;

sub vcl_init {

    # this picks from a group of backend varnishes based on hash of request urls
    new hashdir = directors.hash();
    hashdir.add_backend(backendvarnish1,1);
    hashdir.add_backend(backendvarnish2,1);
    hashdir.add_backend(backendvarnish3,1);

    # this will try a backend varnish or fall back to nginx local which will fetch from the real server
    # currently though we are just forcing to nginx on localhost if the chosen server in the above hash group is down
    # new vdir = directors.fallback();
    # vdir.add_backend(somegenericvarnish);
    # vdir.add_backend(localnginx);
}


sub vcl_recv {

    if (req.restarts == 0) {
    	# try fetching from the hashed backend group
        set req.backend_hint = hashdir.backend(req.url);
    } else {
    	# try fetching with nginx if we restarted due to an error
        # set req.backend_hint = vdir.backend();
        set req.backend_hint = localnginx;
    }

    unset req.http.cookie;
    return (hash);
}

sub vcl_backend_response {

    # these should have been done by backend varnish
    # but in case we fetched via nginx...
    unset beresp.http.cache-control;
    unset beresp.http.expires;

    set beresp.ttl = 1h;
    set beresp.grace = 6h;
}

sub vcl_deliver {

    # try once more in case the hash servers are down
    if ( req.restarts == 0 &&
        resp.status != 200 && resp.status != 403 && resp.status != 404 &&
        resp.status != 301 && resp.status != 302 && resp.status != 307 &&
        resp.status != 410) {
        return(restart);
    }

    set resp.http.frontendvarnish = "lol";

    if (obj.hits > 0) {
        set resp.http.j-front-cache = "hit";
    } else {
        set resp.http.j-front-cache = "miss";
    }
}

sub vcl_hit {

    return(deliver);
}

sub vcl_miss {
    return(fetch);
}