*"* use this source file for your ABAP unit test classes
CLASS ltcl_redis_test DEFINITION FINAL
  FOR TESTING RISK LEVEL HARMLESS DURATION SHORT.

  PRIVATE SECTION.
    DATA mo_client TYPE REF TO zif_redis_client.

    METHODS setup    RAISING zcx_redis_error.
    METHODS teardown RAISING zcx_redis_error.

    " --- Test Methods ---
    METHODS test_ping               FOR TESTING RAISING zcx_redis_error.
    METHODS test_set_get            FOR TESTING RAISING zcx_redis_error.
    METHODS test_long_string        FOR TESTING RAISING zcx_redis_error.
    METHODS test_utf8_and_special   FOR TESTING RAISING zcx_redis_error.
    METHODS test_json_object        FOR TESTING RAISING zcx_redis_error.
    METHODS test_multiple_get       FOR TESTING RAISING zcx_redis_error.
    METHODS test_hash_complex       FOR TESTING RAISING zcx_redis_error.
    METHODS test_list_commands      FOR TESTING RAISING zcx_redis_error.
    METHODS test_sets_unique        FOR TESTING RAISING zcx_redis_error.
    METHODS test_sorted_sets        FOR TESTING RAISING zcx_redis_error.
    METHODS test_transactions_multi FOR TESTING RAISING zcx_redis_error.
    METHODS test_large_array_bulk   FOR TESTING RAISING zcx_redis_error.
    METHODS test_non_existent       FOR TESTING RAISING zcx_redis_error.
    METHODS test_empty_values       FOR TESTING RAISING zcx_redis_error.
ENDCLASS.


CLASS ltcl_redis_test IMPLEMENTATION.
  METHOD setup.
    " Initialize connection to local Redis instance
    mo_client = zcl_redis_client_factory=>create( iv_host = '127.0.0.1'
                                                  iv_port = '6379' ).
    mo_client->connect( ).
  ENDMETHOD.

  METHOD teardown.
    " Gracefully close the connection
    IF mo_client IS BOUND AND mo_client->is_connected( ) = abap_true.
      mo_client->disconnect( ).
    ENDIF.
  ENDMETHOD.

  METHOD test_ping.
    " Verify basic heartbeat
    DATA ls_res TYPE zif_redis_client=>ty_result.

    ls_res = mo_client->ping( ).
    cl_abap_unit_assert=>assert_equals( exp = 'PONG'
                                        act = ls_res-response
                                        msg = 'PING failed' ).
  ENDMETHOD.

  METHOD test_set_get.
    " Basic SET/GET cycle with key cleanup
    DATA lv_key TYPE string                      VALUE 'BASIC_KEY'.
    DATA lv_val TYPE string                      VALUE 'BasicValue'.
    DATA ls_res TYPE zif_redis_client=>ty_result.

    mo_client->set( iv_key = lv_key
                    iv_val = lv_val ).
    ls_res = mo_client->get( lv_key ).

    cl_abap_unit_assert=>assert_equals( exp = lv_val
                                        act = ls_res-response ).
    mo_client->del( lv_key ).
  ENDMETHOD.

  METHOD test_long_string.
    " Validate handling of large payloads to ensure buffer doesn't overflow
    DATA lv_long_val TYPE string.
    DATA ls_res      TYPE zif_redis_client=>ty_result.
    DATA lv_key      TYPE string VALUE 'LONG_STR_KEY'.

    DO 500 TIMES.
      lv_long_val = |{ lv_long_val }DATA_PACKET_{ sy-index }_|.
    ENDDO.

    mo_client->set( iv_key = lv_key
                    iv_val = lv_long_val ).
    ls_res = mo_client->get( lv_key ).

    cl_abap_unit_assert=>assert_equals( exp = lv_long_val
                                        act = ls_res-response
                                        msg = 'Long string data integrity failed' ).
    mo_client->del( lv_key ).
  ENDMETHOD.

  METHOD test_utf8_and_special.
    " Ensure character encoding (UTF-8) is preserved correctly
    DATA lv_key TYPE string                      VALUE 'SPECIAL_CHAR_KEY'.
    DATA lv_val TYPE string                      VALUE 'ÖİÜçşğ - @€ß$ - UnicodeTest'.
    DATA ls_res TYPE zif_redis_client=>ty_result.

    mo_client->set( iv_key = lv_key
                    iv_val = lv_val ).
    ls_res = mo_client->get( lv_key ).

    cl_abap_unit_assert=>assert_equals( exp = lv_val
                                        act = ls_res-response
                                        msg = 'UTF-8 character encoding failed' ).
    mo_client->del( lv_key ).
  ENDMETHOD.

  METHOD test_json_object.
    " Verify interoperability with standard JSON tools (Deep structures)
    TYPES: BEGIN OF ty_sub,
             item  TYPE string,
             count TYPE i,
           END OF ty_sub.
    TYPES: BEGIN OF ty_main,
             id    TYPE i,
             items TYPE STANDARD TABLE OF ty_sub WITH EMPTY KEY,
           END OF ty_main.

    DATA ls_data_in  TYPE ty_main.
    DATA ls_data_out TYPE ty_main.
    DATA lv_json     TYPE string.
    DATA ls_res      TYPE zif_redis_client=>ty_result.
    DATA lv_key      TYPE string VALUE 'JSON_KEY'.

    ls_data_in-id = 100.
    APPEND VALUE #( item  = 'Alpha'
                    count = 1 ) TO ls_data_in-items.
    APPEND VALUE #( item  = 'Beta'
                    count = 2 ) TO ls_data_in-items.

    lv_json = /ui2/cl_json=>serialize( data = ls_data_in ).
    mo_client->set( iv_key = lv_key
                    iv_val = lv_json ).

    ls_res = mo_client->get( lv_key ).
    /ui2/cl_json=>deserialize( EXPORTING json = ls_res-response
                               CHANGING  data = ls_data_out ).

    cl_abap_unit_assert=>assert_equals( exp = ls_data_in-id
                                        act = ls_data_out-id ).
    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lines( ls_data_out-items ) ).
    mo_client->del( lv_key ).
  ENDMETHOD.

  METHOD test_multiple_get.
    " Test Multi-Bulk response (MGET)
    DATA lt_args TYPE zif_redis_client=>tt_string_table.
    DATA ls_res  TYPE zif_redis_client=>ty_result.
    DATA lv_val  TYPE string.

    mo_client->set( iv_key = 'K1'
                    iv_val = 'V1' ).
    mo_client->set( iv_key = 'K2'
                    iv_val = 'V2' ).

    lt_args = VALUE #( ( |MGET| ) ( |K1| ) ( |K2| ) ).
    ls_res = mo_client->call( lt_args ).

    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lines( ls_res-response_table ) ).
    READ TABLE ls_res-response_table INTO lv_val INDEX 2.
    cl_abap_unit_assert=>assert_subrc( 0 ).
    cl_abap_unit_assert=>assert_equals( exp = 'V2'
                                        act = lv_val ).

    mo_client->del( 'K1' ).
    mo_client->del( 'K2' ).
  ENDMETHOD.

  METHOD test_hash_complex.
    " Test Hash Maps with multiple fields
    DATA lt_args TYPE zif_redis_client=>tt_string_table.
    DATA ls_res  TYPE zif_redis_client=>ty_result.

    lt_args = VALUE #( ( |HSET| ) ( |H1| ) ( |f1| ) ( |v1| ) ( |f2| ) ( |v2| ) ).
    mo_client->call( lt_args ).

    lt_args = VALUE #( ( |HGETALL| ) ( |H1| ) ).
    ls_res = mo_client->call( lt_args ).

    cl_abap_unit_assert=>assert_equals( exp = 4
                                        act = lines( ls_res-response_table ) ).
    mo_client->del( 'H1' ).
  ENDMETHOD.

  METHOD test_transactions_multi.
    " Test Atomic Transactions (MULTI/EXEC)
    DATA ls_res TYPE zif_redis_client=>ty_result.

    mo_client->call( VALUE #( ( |MULTI| ) ) ).
    mo_client->set( iv_key = 'T1'
                    iv_val = 'X' ).
    mo_client->set( iv_key = 'T2'
                    iv_val = 'Y' ).
    ls_res = mo_client->call( VALUE #( ( |EXEC| ) ) ).

    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lines( ls_res-response_table ) ).
    mo_client->del( 'T1' ).
    mo_client->del( 'T2' ).
  ENDMETHOD.

  METHOD test_large_array_bulk.
    " Stress test for parser to handle large arrays (1000 items)
    DATA lt_args TYPE zif_redis_client=>tt_string_table.
    DATA ls_res  TYPE zif_redis_client=>ty_result.
    DATA lv_key  TYPE string VALUE 'STRESS_LIST'.

    mo_client->del( lv_key ).
    lt_args = VALUE #( ( |RPUSH| ) ( lv_key ) ).
    DO 1000 TIMES.
      APPEND |VAL_{ sy-index }| TO lt_args.
    ENDDO.
    mo_client->call( lt_args ).

    ls_res = mo_client->call( VALUE #( ( |LRANGE| ) ( lv_key ) ( |0| ) ( |-1| ) ) ).
    cl_abap_unit_assert=>assert_equals( exp = 1000
                                        act = lines( ls_res-response_table ) ).
    mo_client->del( lv_key ).
  ENDMETHOD.

  METHOD test_empty_values.
    " Test edge cases for empty and null-like values
    DATA ls_res TYPE zif_redis_client=>ty_result.

    mo_client->set( iv_key = 'EMPTY'
                    iv_val = '' ).
    ls_res = mo_client->get( 'EMPTY' ).
    cl_abap_unit_assert=>assert_initial( act = ls_res-response ).

    mo_client->set( iv_key = 'SPACES'
                    iv_val = '   ' ).
    ls_res = mo_client->get( 'SPACES' ).
    cl_abap_unit_assert=>assert_equals( exp = '   '
                                        act = ls_res-response ).
  ENDMETHOD.

  METHOD test_non_existent.
    " Verify that missing keys return initial response (RESP Nil handling)
    DATA ls_res TYPE zif_redis_client=>ty_result.

    ls_res = mo_client->get( 'NON_EXISTENT_RANDOM_KEY' ).
    cl_abap_unit_assert=>assert_initial( act = ls_res-response ).
  ENDMETHOD.

  METHOD test_list_commands.
    " Test Redis Lists: L-commands (LPUSH, LPOP) and R-commands (RPUSH, LRANGE)
    DATA lt_args TYPE zif_redis_client=>tt_string_table.
    DATA ls_res  TYPE zif_redis_client=>ty_result.
    DATA lv_key  TYPE string VALUE 'UNIT_TEST_LIST'.

    " Cleanup before starting
    mo_client->del( lv_key ).

    " 1. Push multiple items to the right of the list
    lt_args = VALUE #( ( |RPUSH| ) ( lv_key ) ( |Alpha| ) ( |Beta| ) ( |Gamma| ) ).
    mo_client->call( lt_args ).

    " 2. Pop the first element from the left (FIFO check)
    ls_res = mo_client->call( VALUE #( ( |LPOP| ) ( lv_key ) ) ).
    cl_abap_unit_assert=>assert_equals( exp = 'Alpha'
                                        act = ls_res-response
                                        msg = 'LPOP failed to return the first element' ).

    " 3. Verify remaining elements using LRANGE (0 to -1 returns all)
    ls_res = mo_client->call( VALUE #( ( |LRANGE| ) ( lv_key ) ( |0| ) ( |-1| ) ) ).
    cl_abap_unit_assert=>assert_equals( exp = 2
                                        act = lines( ls_res-response_table )
                                        msg = 'LRANGE should return 2 elements' ).

    mo_client->del( lv_key ).
  ENDMETHOD.

  METHOD test_sets_unique.
    " Test Redis Sets: Ensuring member uniqueness and SADD/SMEMBERS logic
    DATA lt_args TYPE zif_redis_client=>tt_string_table.
    DATA ls_res  TYPE zif_redis_client=>ty_result.
    DATA lv_key  TYPE string VALUE 'UNIT_TEST_SET'.

    mo_client->del( lv_key ).

    " 1. Add members to set (including a duplicate)
    " Redis Sets automatically handle uniqueness
    lt_args = VALUE #( ( |SADD| ) ( lv_key ) ( |M1| ) ( |M2| ) ( |M1| ) ( |M3| ) ).
    mo_client->call( lt_args ).

    " 2. Check total count (SCARD)
    ls_res = mo_client->call( VALUE #( ( |SCARD| ) ( lv_key ) ) ).
    " M1, M2, M3
    cl_abap_unit_assert=>assert_equals( exp = '3'
                                        act = ls_res-response
                                        msg = 'Set uniqueness failed: Expected 3 unique members' ).

    " 3. Check if a specific member exists (SISMEMBER)
    ls_res = mo_client->call( VALUE #( ( |SISMEMBER| ) ( lv_key ) ( |M2| ) ) ).
    " 1 = True in Redis
    cl_abap_unit_assert=>assert_equals( exp = '1'
                                        act = ls_res-response ).

    mo_client->del( lv_key ).
  ENDMETHOD.

  METHOD test_sorted_sets.
    " Test Redis Sorted Sets: Validating Scores and Ranking
    DATA lt_args TYPE zif_redis_client=>tt_string_table.
    DATA ls_res  TYPE zif_redis_client=>ty_result.
    DATA lv_key  TYPE string VALUE 'UNIT_TEST_ZSET'.
    DATA lv_val  TYPE string.

    mo_client->del( lv_key ).

    " 1. Add members with scores (ZADD key score member)
    " We add out of order to test if Redis sorts them correctly
    lt_args = VALUE #( ( |ZADD| )
                       ( lv_key )
                       ( |100| )
                       ( |Winner| )
                       ( |10| )
                       ( |Loser| )
                       ( |50| )
                       ( |Average| ) ).
    mo_client->call( lt_args ).

    " 2. Get members by rank in reverse order (highest score first)
    " ZREVRANGE key 0 0 -> Returns only the member with the highest score
    ls_res = mo_client->call( VALUE #( ( |ZREVRANGE| ) ( lv_key ) ( |0| ) ( |0| ) ) ).

    READ TABLE ls_res-response_table INTO lv_val INDEX 1.
    cl_abap_unit_assert=>assert_subrc( 0 ).
    cl_abap_unit_assert=>assert_equals( exp = 'Winner'
                                        act = lv_val
                                        msg = 'ZREVRANGE failed to return the highest score member' ).

    " 3. Check rank of a specific member (ZRANK)
    " Rank is 0-indexed based on ascending order (Loser=0, Average=1, Winner=2)
    ls_res = mo_client->call( VALUE #( ( |ZRANK| ) ( lv_key ) ( |Average| ) ) ).
    cl_abap_unit_assert=>assert_equals( exp = '1'
                                        act = ls_res-response ).

    mo_client->del( lv_key ).
  ENDMETHOD.
ENDCLASS.
