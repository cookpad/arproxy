# Change Log
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
