CLASS zcl_redis_socket DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    METHODS constructor
      IMPORTING iv_timeout TYPE i DEFAULT zif_redis_socket=>co_default_timeout.

    METHODS set_client
      IMPORTING io_client TYPE REF TO if_apc_wsp_client.

    INTERFACES zif_redis_socket.
    INTERFACES if_apc_wsp_event_handler.

  PRIVATE SECTION.
    DATA mo_client  TYPE REF TO if_apc_wsp_client.
    DATA mv_active  TYPE abap_bool.
    DATA mv_signal  TYPE abap_bool.
    DATA mv_buffer  TYPE xstring.
    DATA mv_timeout TYPE i.

    METHODS wait_socket
      RAISING zcx_redis_error.
ENDCLASS.


CLASS zcl_redis_socket IMPLEMENTATION.
  METHOD constructor.
    mv_timeout = iv_timeout.
  ENDMETHOD.

  METHOD set_client.
    mo_client = io_client.
  ENDMETHOD.

  METHOD zif_redis_socket~is_active.
    rv_result = mv_active.
  ENDMETHOD.

  METHOD zif_redis_socket~reset.
    CLEAR mv_buffer.
  ENDMETHOD.

  METHOD zif_redis_socket~connect.
    DATA lx_apc TYPE REF TO cx_apc_error.

    TRY.
        mo_client->connect( ).
      CATCH cx_apc_error INTO lx_apc.
        zcx_redis_error=>raise( |Connection failed:{ lx_apc->get_text( ) }| ).
    ENDTRY.
  ENDMETHOD.

  METHOD zif_redis_socket~disconnect.
    DATA lx_apc TYPE REF TO cx_apc_error.

    TRY.
        mo_client->close( ).
      CATCH cx_apc_error INTO lx_apc.
        zcx_redis_error=>raise( |Disconnection failed:{ lx_apc->get_text( ) }| ).
    ENDTRY.
  ENDMETHOD.

  METHOD zif_redis_socket~write.
    DATA lo_message_manager TYPE REF TO if_apc_wsp_message_manager.
    DATA lo_message         TYPE REF TO if_apc_wsp_message.
    DATA lx_error           TYPE REF TO cx_apc_error.

    TRY.
        zif_redis_socket~reset( ).

        lo_message_manager ?= mo_client->get_message_manager( ).
        lo_message         ?= lo_message_manager->create_message( ).
        lo_message->set_binary( iv_buffer ).
        lo_message_manager->send( lo_message ).
      CATCH cx_apc_error INTO lx_error.
        zcx_redis_error=>raise( |Sending failed:{ lx_error->get_text( ) }| ).
    ENDTRY.
  ENDMETHOD.

  METHOD zif_redis_socket~read.
    WHILE xstrlen( mv_buffer ) < iv_size.
      wait_socket( ).
    ENDWHILE.

    IF iv_size > 0.
      rv_result = mv_buffer(iv_size).
      mv_buffer = mv_buffer+iv_size.
    ENDIF.
  ENDMETHOD.

  METHOD zif_redis_socket~read_line.
    CONSTANTS lc_len TYPE i VALUE 2.

    DATA lv_pos TYPE i.

    DO.
      FIND FIRST OCCURRENCE OF zif_redis_socket=>co_crlf
           IN mv_buffer IN BYTE MODE
           MATCH OFFSET lv_pos.
      IF sy-subrc = 0.
        rv_result = zif_redis_socket~read( lv_pos + lc_len ).
        RETURN.
      ENDIF.
      wait_socket( ).
    ENDDO.
  ENDMETHOD.

  METHOD wait_socket.
    IF mv_active = abap_false.
      zcx_redis_error=>raise( 'Connection is closed. Unable to read data from Redis.' ).
    ENDIF.

    mv_signal = abap_false.

    WAIT FOR PUSH CHANNELS
         UNTIL mv_signal = abap_true
         UP TO mv_timeout SECONDS.
    IF sy-subrc <> 0.
      zcx_redis_error=>raise( 'Socket timeout exceeded.' ).
    ENDIF.
  ENDMETHOD.

  METHOD if_apc_wsp_event_handler~on_message.
    DATA lv_response TYPE xstring.

    TRY.
        lv_response = i_message->get_binary( ).

        mv_signal = abap_true.

        CONCATENATE mv_buffer lv_response INTO mv_buffer IN BYTE MODE.
      CATCH cx_root.
    ENDTRY.
  ENDMETHOD.

  METHOD if_apc_wsp_event_handler~on_close.
    mv_active = abap_false.
  ENDMETHOD.

  METHOD if_apc_wsp_event_handler~on_error.
    CLEAR mv_buffer.
  ENDMETHOD.

  METHOD if_apc_wsp_event_handler~on_open.
    mv_active = abap_true.
  ENDMETHOD.
ENDCLASS.
