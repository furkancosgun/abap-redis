CLASS zcl_redis_parser DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES zif_redis_parser.

    CLASS-METHODS convert_to_string
      IMPORTING iv_xstring       TYPE xstring
      RETURNING VALUE(rv_string) TYPE string.

    CLASS-METHODS convert_to_xstring
      IMPORTING iv_string         TYPE string
      RETURNING VALUE(rv_xstring) TYPE xstring.

  PRIVATE SECTION.
    METHODS _deserialize
      IMPORTING io_socket        TYPE REF TO zif_redis_socket
      RETURNING VALUE(rs_result) TYPE zif_redis_client=>ty_result
      RAISING   zcx_redis_error.
ENDCLASS.


CLASS zcl_redis_parser IMPLEMENTATION.
  METHOD zif_redis_parser~serialize.
    FIELD-SYMBOLS <fs_args> TYPE string.
    DATA lv_val TYPE xstring.

    rv_result = convert_to_xstring( |*{ lines( it_args ) }| ) && zif_redis_socket=>co_crlf.

    LOOP AT it_args ASSIGNING <fs_args>.
      lv_val = convert_to_xstring( <fs_args> ).
      rv_result = rv_result && convert_to_xstring( |${ xstrlen( lv_val ) }| ) && zif_redis_socket=>co_crlf.
      rv_result = rv_result && lv_val && zif_redis_socket=>co_crlf.
    ENDLOOP.
  ENDMETHOD.

  METHOD zif_redis_parser~deserialize.
    rs_result = _deserialize( io_socket ).
  ENDMETHOD.

  METHOD _deserialize.
    DATA lv_reply    TYPE xstring.
    DATA lv_head_str TYPE string.
    DATA lv_val_str  TYPE string.
    DATA lv_size     TYPE i.
    DATA lv_raw      TYPE xstring.

    lv_reply = io_socket->read_line( ).
    IF xstrlen( lv_reply ) = 0.
      RETURN.
    ENDIF.

    lv_head_str = convert_to_string( lv_reply ).

    lv_val_str = segment( val   = substring( val = lv_head_str
                                             off = 1 )
                          index = 1
                          sep   = cl_abap_char_utilities=>cr_lf ).

    CASE lv_reply(1).
      WHEN zif_redis_parser=>co_types-error.
        zcx_redis_error=>raise( |Redis Error: { lv_val_str }| ).
      WHEN zif_redis_parser=>co_types-simple_string.
        rs_result-response = lv_val_str.
      WHEN zif_redis_parser=>co_types-integer.
        rs_result-response = lv_val_str.
      WHEN zif_redis_parser=>co_types-bulk_string.
        lv_size = lv_val_str.
        IF lv_size > 0.
          lv_raw = io_socket->read( lv_size ).
          rs_result-response = convert_to_string( lv_raw ).
          io_socket->read( 2 ).
        ELSEIF lv_size = 0.
          rs_result-response = ''.
        ENDIF.
      WHEN zif_redis_parser=>co_types-array.
        lv_size = lv_val_str.
        IF lv_size <= 0.
          RETURN.
        ENDIF.
        DO lv_size TIMES.
          APPEND _deserialize( io_socket )-response TO rs_result-response_table.
        ENDDO.
    ENDCASE.
  ENDMETHOD.

  METHOD convert_to_string.
    rv_string = cl_abap_codepage=>convert_from( iv_xstring ).
  ENDMETHOD.

  METHOD convert_to_xstring.
    rv_xstring = cl_abap_codepage=>convert_to( iv_string ).
  ENDMETHOD.
ENDCLASS.
