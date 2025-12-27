INTERFACE zif_redis_socket
  PUBLIC.

  CONSTANTS co_cr              TYPE x LENGTH 1 VALUE '0D'.
  CONSTANTS co_lf              TYPE x LENGTH 1 VALUE '0A'.
  CONSTANTS co_crlf            TYPE x LENGTH 2 VALUE '0D0A'.
  CONSTANTS co_default_timeout TYPE i          VALUE 10.

  METHODS connect
    RAISING zcx_redis_error.

  METHODS disconnect
    RAISING zcx_redis_error.

  METHODS is_active
    RETURNING VALUE(rv_result) TYPE abap_bool.

  METHODS reset.

  METHODS write
    IMPORTING iv_buffer TYPE xstring
    RAISING   zcx_redis_error.

  METHODS read
    IMPORTING iv_size          TYPE i
    RETURNING VALUE(rv_result) TYPE xstring
    RAISING   zcx_redis_error.

  METHODS read_line
    RETURNING VALUE(rv_result) TYPE xstring
    RAISING   zcx_redis_error.

ENDINTERFACE.
