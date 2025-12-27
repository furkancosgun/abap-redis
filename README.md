# ABAP Redis Client

**ABAP Redis Client** is a lightweight Redis client library for ABAP environments. It provides a simple, modern ABAP interface to call Redis commands, serialize/deserialize multi-bulk responses, and integrate with ABAP Unit tests.

---

## ✅ Features

- Simple client interface (`zif_redis_client`) with high-level helpers (`get`, `set`, `ping`, `call`, etc.)
- Factory for easy client creation (`zcl_redis_client_factory`) with TCP connection setup
- Parser & socket layers separated (`zcl_redis_parser`, `zcl_redis_socket`)
- Robust unit tests demonstrating real usage patterns (see `src/zcl_redis_client.clas.testclasses.abap`)

---

## ⚙️ Requirements

- SAP NetWeaver / ABAP runtime with ABAP Objects
- `cl_apc_tcp_client_manager` available for TCP client support
- `/ui2/cl_json` (used in examples for JSON serialization)

---

## 🚀 Quick Start

1. Create the client using the factory (defaults to `127.0.0.1:6379`):

```abap
DATA(lo_client) = zcl_redis_client_factory=>create(
  iv_host = '127.0.0.1'
  iv_port = '6379'
).

lo_client->connect( ).
```

2. Ping Redis:

```abap
DATA(ls_res) = lo_client->ping( ).
WRITE ls_res-response. " Expected: 'PONG' "
```

3. Basic SET / GET:

```abap
lo_client->set(
  iv_key = 'BASIC_KEY'
  iv_val = 'BasicValue'
).

ls_res = lo_client->get( iv_key = 'BASIC_KEY' ).
WRITE ls_res-response. " 'BasicValue' 

lo_client->del( iv_key = 'BASIC_KEY' ).
```

4. Store a JSON object:

```abap
TYPES: BEGIN OF ty_item,
         item  TYPE string,
         count TYPE i,
       END OF ty_item.

TYPES: BEGIN OF ty_main,
         id    TYPE i,
         items TYPE STANDARD TABLE OF ty_item WITH EMPTY KEY,
       END OF ty_main.

DATA(ls_in) = VALUE ty_main(
  id    = 100
  items = VALUE #( ( item = 'Alpha' count = 1 ) ( item = 'Beta' count = 2 ) )
).

DATA(lv_json) = /ui2/cl_json=>serialize( data = ls_in ).

lo_client->set(
  iv_key = 'JSON_KEY'
  iv_val = lv_json
).

ls_res = lo_client->get( 'JSON_KEY' ).

DATA(ls_out) TYPE ty_main.

/ui2/cl_json=>deserialize(
  EXPORTING
    json = ls_res-response
  CHANGING
    data = ls_out
).
```

5. Call arbitrary Redis commands (MGET example):

```abap
DATA(lt_args) = VALUE zif_redis_client=>tt_string_table(
  ( |MGET| )
  ( |K1| )
  ( |K2| )
).

ls_res = lo_client->call( lt_args ).
" ls_res-response_table contains returned values for each key "
```

---

## 📚 API Summary

Interface: `zif_redis_client`

- TYPES: `tt_string_table` (table of strings), `ty_result` (response & response_table)

- METHODS:
  - `connect` - connect to Redis server
  - `disconnect` - close connection
  - `is_connected` / `is_disconnected` - connection checks
  - `call( it_args )` - low level command caller (returns `ty_result`)
  - `ping()` - convenience ping
  - `get( iv_key )` / `set( iv_key, iv_val, iv_exp )` - key-value
  - `del( iv_key )` / `exists( iv_key )` / `expire( iv_key, iv_seconds )` / `ttl( iv_key )`
  - `info()` - retrieve server info

For more examples, see the unit tests: `src/zcl_redis_client.clas.testclasses.abap` which contains examples for lists, sets, sorted sets, hashes, transactions, JSON usage, and edge-case handling (empty values, long strings, UTF-8).

---

## 🧪 Tests

- The ABAP unit tests live in `src/zcl_redis_client.clas.testclasses.abap`. They demonstrate real usage patterns and assertions using `cl_abap_unit_assert`.
- Locally (project-level tooling):

```bash
npm install
npm run test   # runs abaplint + transpile & node runner
```

> Note: `npm run test` uses the included transpiler and node harness (see `package.json`). Running ABAP Unit tests against an SAP system requires importing the classes into your system and running them in SE80 or via your usual CI.

---

## 🧾 License

This project is licensed under the **MIT** License. See `LICENSE` for details.

---

## 💡 Contribution

Contributions, bug reports and feature requests are welcome. Please open an issue or submit a PR on the project's GitHub page.

