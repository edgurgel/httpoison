# Changelog

Check https://github.com/edgurgel/httpoison/releases

# 3.0.0 (2026-06-14)
* Upgrade to hackney 4.0, which fixes several CVEs (atom-table exhaustion via URL schemes, HTTP header injection, WebSocket buffer limits and more)
* Response bodies now come straight from hackney; `max_body_length` is trimmed on our side
* Redirects are now followed inside hackney, so `HTTPoison.MaybeRedirect` is no longer returned. The struct is kept only for backward compatibility
* `ssl: [verify: :verify_none]` disables certificate verification again
* Skip empty chunks when streaming a request body so they don't truncate the request
* Basic auth over plain HTTP now requires the `insecure_basic_auth: true` option
