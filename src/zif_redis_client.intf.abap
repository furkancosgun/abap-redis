INTERFACE zif_redis_client
  PUBLIC.
  TYPES tt_string_table TYPE STANDARD TABLE OF string WITH EMPTY KEY.

  TYPES:
    BEGIN OF ty_result,
      response       TYPE string,
      response_table TYPE tt_string_table,
    END OF ty_result.

  METHODS connect
    RAISING zcx_redis_error.

  METHODS disconnect
    RAISING zcx_redis_error.

  METHODS is_connected
    RETURNING VALUE(rv_result) TYPE abap_bool.

  METHODS is_disconnected
    RETURNING VALUE(rv_result) TYPE abap_bool.

  METHODS call
    IMPORTING it_args          TYPE tt_string_table
    RETURNING VALUE(rs_result) TYPE ty_result
    RAISING   zcx_redis_error.

  METHODS ping
    RETURNING VALUE(rs_result) TYPE ty_result
    RAISING   zcx_redis_error.

  METHODS get
    IMPORTING iv_key           TYPE string
    RETURNING VALUE(rs_result) TYPE ty_result
    RAISING   zcx_redis_error.

  METHODS set
    IMPORTING iv_key           TYPE string
              iv_val           TYPE string
              iv_exp           TYPE i OPTIONAL
    RETURNING VALUE(rs_result) TYPE ty_result
    RAISING   zcx_redis_error.

  METHODS del
    IMPORTING iv_key           TYPE string
    RETURNING VALUE(rs_result) TYPE ty_result
    RAISING   zcx_redis_error.

  METHODS exists
    IMPORTING iv_key           TYPE string
    RETURNING VALUE(rs_result) TYPE ty_result
    RAISING   zcx_redis_error.

  METHODS expire
    IMPORTING iv_key           TYPE string
              iv_seconds       TYPE i
    RETURNING VALUE(rs_result) TYPE ty_result
    RAISING   zcx_redis_error.

  METHODS ttl
    IMPORTING iv_key           TYPE string
    RETURNING VALUE(rs_result) TYPE ty_result
    RAISING   zcx_redis_error.

  METHODS info
    RETURNING VALUE(rs_result) TYPE ty_result
    RAISING   zcx_redis_error.
ENDINTERFACE.
