# Changelog

# 0.13.0 (2017-08-04)

* Relax hackney requirement (#277). Thanks to @tverlaan

# 0.12.0 (2017-06-29)

* Change HTTPoison transformer to always `spawn_link` (#260)
* Add `request_url` to `HTTPoison.Response` (#270)

# 0.11.2 (2017-04-23)

* Bump hackney version requirement (#244). Thanks @jakehasler
* Add support to encode URLs containing a query string (#223). Thanks @jadlr

# 0.11.1 (2017-03-02)

* Add `process_request_options` (#208). Thanks to @drewolson
* Bump hackney to `~> 1.7.0` (#228). Thanks to @xinz
* Change typespec of `Response.body` (#220). Thanks to @deepblue
* Add test for a GET request (#219). Thanks to @Lokeh

# 0.11.0 (2017-01-08)

* Add `{:stream, enumerable}` body option (#194). Thanks to @rozap :tada:;
* Change overridable functions to be public (#201). Thanks to @paulswartz :tada:;

# 0.10.0 (2016-11-06)

* Add support for http over unix sockets - requires hackney >= 1.6.3, erlang >= 19. (#185).
* Add support for hackney async once & stream_next/1

# 0.9.2 (2016-09-27)

* Rewrite `request!/5` in a way that does not cause OTP 19 cover to error (#178);
* Add `put/1` (#175);
* [Revert](https://github.com/edgurgel/httpoison/commit/208344000c5d843ad9e89c2c9951ea01d8b6f68a) `process_` errors bubbling up.

# 0.9.1 (2016-08-29)

* Fix Elixir 1.4 warnings (#166). Thanks to @whatyouhide :tada:;
* Bubble `process_` errors up (#169). Thanks to @mootpointer :tada:.

# 0.9.0 (2016-06-25)

* Add a test and an example of using multiple cookies (#135);
* Change `request/5` to catch hackney errors (#141);
* Bump Elixir requirement to `~> 1.2`;
* A couple of changes to README (#133, #136);
* Fix several typos (#142, #146).

# 0.8.2 (2016-03-16)

* Bump hackney requirement (#131).

# 0.8.1 (2016-01-14)

* Fix socket leakage related to 204/304 requests;
* Update README and docs.

# 0.8.0 (2015-11-08)

* Update hackney requirement to `~> 1.4.4`.

# 0.7.5 (2015-11-08)

* Rewrite docs for `HTTPoison.Base.request/5`;
* Fix async redirect process leak (#80). Thanks to @sdanzan :tada:;
* Add hackney redirect options to HTTPoison (#84). Thanks to @ShaneWilton :tada:.

# 0.7.4 (2015-09-21)

* Refactor generated functions through `HTTPoison.Base`;
* Add `ssl` option.

# 0.7.3 (2015-09-02)

* Accept `proxy_auth` as a first class parameter;
* Update ex_doc and earmark.

# 0.7.2 (2015-08-11)

* Use hackney default values for options;
* Require hackney `~> 1.3.1` (#64).

# 0.7.1 (2015-07-28)

* Update hackney requirement to `~> 1.3.0`.

## 0.7.0 (2015-06-06)

* Add missing docs. Thanks to @whatyouhide;
* **[Breaking change]** Use list of tuples of strings instead of a dict. Thanks to @tyrchen.

## 0.6.2 (2015-02-17)

* Add documentation for public functions on `HTTPoison.Base`. Thanks to @whatyouhide.

## 0.6.1 (2015-02-11)

* Add support to `proxy` option. Thanks to @povilas;
* Add support to `params` option. Thanks to @whatyouhide.

## 0.6.0 (2015-01-26)

* This version does not include any feature. It specifies a newer version to hackney: `~> 1.0` as it brought lots of bugfixes and more stability.

## 0.5.0 (2014-10-14)

* API breaking changes:

  * `HTTPoison.HTTPError` was renamed to `HTTPoison.Error`;
  * Requests will now return `{:ok, response}` or `{:error, error}`;
  * The old behaviour will be followed by new functions with bang, example:

`HTTPoison.get!` will follow the old behaviour of `HTTPoison.get`

Related discussion: https://github.com/edgurgel/httpoison/issues/27.

## 0.4.3 (2014-10-09)

* Update hackney to `~> 0.14.1`;
* Fix error raising (#26).

## 0.4.2 (2014-09-03)

* Ensure support to 1.0.0-rc1.

## 0.4.1 (2014-08-22)

* Do not fetch the body on 204, 304 responses. (Thanks to @d0rc);
* Catch body fetching errors and raise proper HTTPError. (Thanks to @sch1zo);
* Use meck hex package on test environment.

## 0.4.0 (2014-08-17)

* Turn `process_*` functions to private functions so you don't need to expose them when overriding;
* Add typespecs.

## 0.3.2 (2014-08-03)

* Ensure support to Elixir 0.15.0;
* Update HTTParrot (using hex package).

## 0.3.0 (2014-08-02)

* Change to MIT License.

## 0.3.0 (2014-06-25)

* Update to Elixir 0.14.1.

## 0.2.0 (2014-06-15)

* Update to Elixir 0.14.0.

## 0.1.1 (2014-05-30)

* Update to Elixir 0.13.3;
* Accept a map on headers;
* Update deps.

## 0.1.0 (2014-04-29)

* Update hackney;
* Use maps/structs instead of ListDicts/records;
* Update to Elixir 0.13.1 and fix deprecation on Application startup (thanks to @knewter);
* This release breaks compatibility with previous versions.

## 0.0.2 (2014-02-13)

* Add tests to HTTPoison.Base;
* Add process_request_headers;
* New logo;
* Use HTTParrot instead of httpbin on tests.;
* Source code (zip).

## 0.0.1 (2014-01-08)

* First release.
