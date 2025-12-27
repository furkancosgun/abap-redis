CLASS zcl_redis_client DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS constructor
      IMPORTING io_socket TYPE REF TO zif_redis_socket
                io_parser TYPE REF TO zif_redis_parser.

    INTERFACES zif_redis_client.

  PRIVATE SECTION.
    DATA mo_parser TYPE REF TO zif_redis_parser.
    DATA mo_socket TYPE REF TO zif_redis_socket.
ENDCLASS.


CLASS zcl_redis_client IMPLEMENTATION.
  METHOD constructor.
    mo_parser = io_parser.
    mo_socket = io_socket.
  ENDMETHOD.

  METHOD zif_redis_client~call.
    DATA lv_buffer TYPE xstring.

    lv_buffer = mo_parser->serialize( it_args = it_args ).

    mo_socket->write( iv_buffer = lv_buffer ).

    rs_result = mo_parser->deserialize( io_socket = mo_socket ).
  ENDMETHOD.

  METHOD zif_redis_client~connect.
    mo_socket->connect( ).
  ENDMETHOD.

  METHOD zif_redis_client~disconnect.
    mo_socket->disconnect( ).
  ENDMETHOD.

  METHOD zif_redis_client~is_connected.
    rv_result = mo_socket->is_active( ).
  ENDMETHOD.

  METHOD zif_redis_client~is_disconnected.
    rv_result = xsdbool( NOT mo_socket->is_active( ) ).
  ENDMETHOD.

  METHOD zif_redis_client~ping.
    rs_result = zif_redis_client~call( it_args = VALUE #( ( |PING| ) ) ).
  ENDMETHOD.

  METHOD zif_redis_client~get.
    rs_result = zif_redis_client~call( it_args = VALUE #( ( |GET| ) ( iv_key ) ) ).
  ENDMETHOD.

  METHOD zif_redis_client~set.
    DATA lt_args TYPE zif_redis_client=>tt_string_table.

    lt_args = VALUE zif_redis_client=>tt_string_table( ( |SET| ) ( iv_key ) ( iv_val ) ).

    IF iv_exp IS SUPPLIED.
      APPEND |EX| TO lt_args.
      APPEND |{ iv_exp }| TO lt_args.
    ENDIF.

    rs_result = zif_redis_client~call( it_args = lt_args ).
  ENDMETHOD.

  METHOD zif_redis_client~del.
    rs_result = zif_redis_client~call( it_args = VALUE #( ( |DEL| ) ( iv_key ) ) ).
  ENDMETHOD.

  METHOD zif_redis_client~exists.
    rs_result = zif_redis_client~call( it_args = VALUE #( ( |EXISTS| ) ( iv_key ) ) ).
  ENDMETHOD.

  METHOD zif_redis_client~expire.
    rs_result = zif_redis_client~call( it_args = VALUE #( ( |EXPIRE| )
                                                          ( iv_key )
                                                          ( |{ iv_seconds }| ) ) ).
  ENDMETHOD.

  METHOD zif_redis_client~ttl.
    rs_result = zif_redis_client~call( it_args = VALUE #( ( |TTL| ) ( iv_key ) ) ).
  ENDMETHOD.

  METHOD zif_redis_client~info.
    rs_result = zif_redis_client~call( it_args = VALUE #( ( |INFO| ) ) ).
  ENDMETHOD.
ENDCLASS.
