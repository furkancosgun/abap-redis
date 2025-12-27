INTERFACE zif_redis_parser
  PUBLIC.

  CONSTANTS:
    BEGIN OF co_types,
      simple_string TYPE x LENGTH 1 VALUE '2B',
      error         TYPE x LENGTH 1 VALUE '2D',
      integer       TYPE x LENGTH 1 VALUE '3A',
      bulk_string   TYPE x LENGTH 1 VALUE '24',
      array         TYPE x LENGTH 1 VALUE '2A',
    END OF co_types.

  METHODS serialize
    IMPORTING it_args          TYPE zif_redis_client=>tt_string_table
    RETURNING VALUE(rv_result) TYPE xstring
    RAISING   zcx_redis_error.

  METHODS deserialize
    IMPORTING io_socket        TYPE REF TO zif_redis_socket
    RETURNING VALUE(rs_result) TYPE zif_redis_client=>ty_result
    RAISING   zcx_redis_error.
ENDINTERFACE.
