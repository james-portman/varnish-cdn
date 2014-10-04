varnish-cdn
===========

Double layered varnish CDN

The idea is user -> varnish (close to the user) -> varnish (backend group) -> backend/website

The user side varnish servers could be chosen either via geodns or anycast IP addresses

The backend varnish servers are picked by the front end based on hash of the url
the backend servers would be a larger group,
while the user servers could be few but better distributed across the globe

Notes:
I suggest running a local dns resolver/cache with google public? as backup

ndjbdns from epel or bind