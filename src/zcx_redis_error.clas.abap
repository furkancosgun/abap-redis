CLASS zcx_redis_error DEFINITION
  PUBLIC
  INHERITING FROM cx_static_check FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_t100_message.
    INTERFACES if_t100_dyn_msg.

    CONSTANTS:
      BEGIN OF mc_general_error,
        msgid TYPE symsgid      VALUE '00',
        msgno TYPE symsgno      VALUE '001',
        attr1 TYPE scx_attrname VALUE 'MV_MSGV1',
        attr2 TYPE scx_attrname VALUE 'MV_MSGV2',
        attr3 TYPE scx_attrname VALUE 'MV_MSGV3',
        attr4 TYPE scx_attrname VALUE 'MV_MSGV4',
      END OF mc_general_error.

    DATA mv_msgv1 TYPE sy-msgv1       READ-ONLY.
    DATA mv_msgv2 TYPE sy-msgv2       READ-ONLY.
    DATA mv_msgv3 TYPE sy-msgv3       READ-ONLY.
    DATA mv_msgv4 TYPE sy-msgv4       READ-ONLY.
    DATA mt_stack TYPE abap_callstack READ-ONLY.

    METHODS constructor
      IMPORTING iv_msgv1 TYPE sy-msgv1 OPTIONAL
                iv_msgv2 TYPE sy-msgv2 OPTIONAL
                iv_msgv3 TYPE sy-msgv3 OPTIONAL
                iv_msgv4 TYPE sy-msgv4 OPTIONAL.

    METHODS get_source_position REDEFINITION.

    CLASS-METHODS raise
      IMPORTING iv_message TYPE string
      RAISING   zcx_redis_error.

    CLASS-METHODS raise_syst
      RAISING zcx_redis_error.

  PROTECTED SECTION.

  PRIVATE SECTION.
    METHODS save_callstack.
ENDCLASS.


CLASS zcx_redis_error IMPLEMENTATION.
  METHOD constructor ##ADT_SUPPRESS_GENERATION.
    super->constructor( ).
    mv_msgv1 = iv_msgv1.
    mv_msgv2 = iv_msgv2.
    mv_msgv3 = iv_msgv3.
    mv_msgv4 = iv_msgv4.
    if_t100_message~t100key = mc_general_error.

    save_callstack( ).
  ENDMETHOD.

  METHOD raise.
    DATA lv_message TYPE c LENGTH 200.

    lv_message = iv_message.

    RAISE EXCEPTION TYPE zcx_redis_error
      EXPORTING iv_msgv1 = lv_message(50)
                iv_msgv2 = lv_message+50(50)
                iv_msgv3 = lv_message+100(50)
                iv_msgv4 = lv_message+150(50).
  ENDMETHOD.

  METHOD raise_syst.
    DATA lv_message TYPE c LENGTH 200.

    MESSAGE ID sy-msgid
            TYPE sy-msgty
            NUMBER sy-msgno
            INTO lv_message
            WITH sy-msgv1
                 sy-msgv2
                 sy-msgv3
                 sy-msgv4.

    RAISE EXCEPTION TYPE zcx_redis_error
      EXPORTING iv_msgv1 = lv_message(50)
                iv_msgv2 = lv_message+50(50)
                iv_msgv3 = lv_message+100(50)
                iv_msgv4 = lv_message+150(50).
  ENDMETHOD.

  METHOD get_source_position.
    FIELD-SYMBOLS <fs_stack> LIKE LINE OF mt_stack.

    ASSIGN mt_stack[ 1 ] TO <fs_stack>.
    IF sy-subrc = 0.
      program_name = <fs_stack>-mainprogram.
      include_name = <fs_stack>-include.
      source_line  = <fs_stack>-line.
    ELSE.
      super->get_source_position( IMPORTING program_name = program_name
                                            include_name = include_name
                                            source_line  = source_line ).
    ENDIF.
  ENDMETHOD.

  METHOD save_callstack.
    FIELD-SYMBOLS <fs_stack> LIKE LINE OF mt_stack.

    CALL FUNCTION 'SYSTEM_CALLSTACK'
      IMPORTING callstack = mt_stack.

    LOOP AT mt_stack ASSIGNING <fs_stack>.
      IF <fs_stack>-mainprogram CP |ZCX_REDIS_ERROR*|.
        DELETE TABLE mt_stack FROM <fs_stack>.
      ELSE.
        EXIT.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.
