# Change Log
## 0.2.8
* Support ActiveRecord 7.0 (#21)
  Thanks to @r7kamura

## 0.2.8
* Support postgresql adapter (#19)
  Thanks to @jhnvz

## 0.2.7
* Support sqlserver adapter (#16)
  Note that it supports `AR::B.connection.execute` but not `exec_query` yet.
  See: https://github.com/cookpad/arproxy/pull/16
  Thanks to @takanamito

## 0.2.6
* Support sqlite3 adapter (#15)
  Thanks to @hakatashi

## 0.2.5
* Fix against warnings around `::` in void context (#12)

## 0.2.4
* Fix against warnings around uninitialized instance variables (#12)
  Thanks to @amatsuda

## 0.2.3
* Set Arproxy::Config#adapter from database.yml automatically (#11)
  Thanks to @k0kubun

## 0.2.2
* Start supporting activerecord-5.0 and stop 3.2-4.1

## 0.2.1
* Make ProxyChain thread-safe (#7)
  Thanks to @saidie

## 0.2.0
* Arproxy plugin: an easy way to make reusable proxies as gems (#6)
  Thanks to @winebarrel

## 0.1.3
* Silence some deprecation warnings (#1)
  Thanks to @amatsuda

* Implement Arproxy.#enable? and Arproxy.#reenable!

## 0.1.2
* Bug fix: An error occoured when call disable! after disable!

* config.adapter accepts not only String but also Class

## 0.1.1
* First Release
