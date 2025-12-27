CLASS zcl_redis_client_factory DEFINITION
  PUBLIC FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    CLASS-METHODS create
      IMPORTING iv_protocol      TYPE i          DEFAULT cl_apc_tcp_client_manager=>co_protocol_type_tcp
                iv_host          TYPE string     DEFAULT '127.0.0.1'
                iv_port          TYPE string     DEFAULT '6379'
                iv_ssl_id        TYPE ssfapplssl DEFAULT 'ANONYM'
                iv_timeout       TYPE i          DEFAULT zif_redis_socket=>co_default_timeout
      RETURNING VALUE(ro_client) TYPE REF TO zif_redis_client
      RAISING   zcx_redis_error.

  PRIVATE SECTION.
    CLASS-METHODS get_tcp_frame RETURNING VALUE(rs_frame) TYPE apc_tcp_frame.
ENDCLASS.


CLASS zcl_redis_client_factory IMPLEMENTATION.
  METHOD create.
    DATA lo_socket TYPE REF TO zcl_redis_socket.
    DATA lo_apc    TYPE REF TO if_apc_wsp_client.
    DATA lx_apc    TYPE REF TO cx_apc_error.

    TRY.
        lo_socket = NEW zcl_redis_socket( iv_timeout = iv_timeout ).

        lo_apc = cl_apc_tcp_client_manager=>create( i_protocol      = iv_protocol
                                                    i_host          = iv_host
                                                    i_port          = iv_port
                                                    i_frame         = get_tcp_frame( )
                                                    i_event_handler = lo_socket
                                                    i_ssl_id        = iv_ssl_id ).

        lo_socket->set_client( lo_apc ).

        ro_client = NEW zcl_redis_client( io_socket = lo_socket
                                          io_parser = NEW zcl_redis_parser( ) ).

      CATCH cx_apc_error INTO lx_apc.
        zcx_redis_error=>raise( |TCP client creation failed: { lx_apc->get_text( ) }| ).
    ENDTRY.
  ENDMETHOD.

  METHOD get_tcp_frame.
    rs_frame-frame_type = if_apc_tcp_frame_types=>co_frame_type_terminator.
    rs_frame-terminator = zif_redis_socket=>co_crlf.
  ENDMETHOD.
ENDCLASS.
