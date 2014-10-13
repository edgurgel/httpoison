# Changelog

## 0.4.3 (2014-09-09)

* Update hackney to ~> 0.14.1
* Fix error raising (#26)

## 0.4.2 (2014-09-03)

* Ensure support to 1.0.0-rc1

## 0.4.1 (2014-08-22)

* Do not fetch the body on 204, 304 responses. (Thanks to @d0rc)
* Catch body fetching errors and raise proper HTTPError. (Thanks to @sch1zo)
* Use meck hex package on test environment.

## 0.4.0 (2014-08-17)

* Turn process_* functions to private functions so you don't need to expose them when overriding;
* Add typespecs.

## 0.3.2 (2014-08-03)

* Ensure support to Elixir 0.15.0
* Update HTTParrot (using hex package)

## 0.3.0 (2014-08-02)

* Change to MIT License

## 0.3.0 (2014-06-25)

* Update to Elixir 0.14.1

## 0.2.0 (2014-06-15)

* Update to Elixir 0.14.0

## 0.1.1 (2014-05-30)

* Update to Elixir 0.13.3;
* Accept a map on headers;
* Update deps;

## 0.1.0 (2014-04-29)

* Update hackney;
* Use maps/structs instead of ListDicts/records;
* Update to Elixir 0.13.1 and fix deprecation on Application startup (thanks to @knewter).
* This release breaks compatibility with previous versions.

## 0.0.2 (2014-02-13)

* Add tests to HTTPoison.Base;
* Add process_request_headers;
* New logo;
* Use HTTParrot instead of httpbin on tests.;
* Source code (zip)

## 0.0.1 (2014-01-08)

* First release
