'!TITLE "Epson robot program"
'#define <constance> <Strings>

String DEV_VENDER$ = "EPSON"
String DEV_IP$ = "NA"
String DEV_PROTO_VER$ = "NA"
String DEV_APP_SW$ = "NA"

#Define ERRORMESSAGE_UPPER_LIMIT   10   
#Define TIMEOUT_TK_REBOOT	       30000                            'no need to change
#Define STATUS_STOP			       3                                'changed
#Define STATUS_RUN			       1                                'changed
#Define STATUS_WAIT                2                                'changed
#Define COMM_STATUS_CLOSE          0                                'unused
#Define COMM_STATUS_CONNECT        2                                'unused
#Define CONNECT_WAIT               100                              'unused
#Define RECV_QUEUE_START           0                                'changed
#Define RECV_QUEUE_UPPER_LIMIT     50                               'changed
#Define SEND_QUEUE_START           0                                'changed
#Define SEND_QUEUE_UPPER_LIMIT     50                               'changed
#Define MOTION_QUEUE_START         0                                'changed
#Define MOTION_QUEUE_UPPER_LIMIT   1500                             'changed
#Define MOTION_CMD_START           0                                'changed
#Define NM_QUEUE_START             0                                'changed
#Define NM_QUEUE_UPPER_LIMIT       600                              'changed
#Define NM_CMD_START               0                                'changed
#Define ARGS_UPPER_LIMIT           30                               'no need to change
#Define SYS_ESTOP                  &H100000 'bit 20                 'changed
#Define AUTOMATION_MODE            &H10000 'bit 16                  'changed, need test
#Define COM_RECV_PORT              4                                ' Commnuication port , unused
#Define COM_TIMEOUT                3                                ' Communication Timeout, unused
#Define COM_SEND_PORT              8                                ' old one for denso, need to be removed
#Define COM_RECV_PORT_NEW          201                              'new for epson
#Define COM_SEND_PORT_NEW          202                              'new for epson
#Define MINI_IO_INPUT_START        0
#Define MINI_IO_INPUT_END          15
#Define MINI_IO_OUTPUT_START       16
#Define MINI_IO_OUTPUT_END         31
#Define HAND_IO_INPUT_START        48
#Define HAND_IO_INPUT_END          55
#Define HAND_IO_OUTPUT_START       64
#Define HAND_IO_OUTPUT_END         71
#Define INTERNAL_IO_START          128
#Define INTERNAL_IO_END            511
#Define PARALLEL_IO_INPUT_START    3584                             'need change later
#Define PARALLEL_IO_INPUT_END      3623
#Define PARALLEL_IO_OUTPUT_START   3840
#Define PARALLEL_IO_OUTPUT_END     3887
#Define MAXSTRLENGTH               200

#Define CHECK_TASK_STATE(x)        TaskState(x) = 0 Or TaskState(x) = 5   'check task is running or waiting or stop, need to verify
#Define SHIFT_POSITION             P101                                   '^ 1 means not running and 0 means running  


'============I-Variable==================
Global Int32 CMD_RECV_FRONT             '0                        
Global Int32 CMD_RECV_BACK              '1                               
Global Int32 BG_TASK_COUNT              '2                             
Global Int32 MOTION_REPLY_SEND          '3                               'unused
Global Int32 MOTION_FRONT               '4
Global Int32 MOTION_BACK                '5
Global Int32 NM_FRONT                   '6
Global Int32 NM_BACK                    '7
Global Int32 CMD_SEND_FRONT             '8
Global Int32 CMD_SEND_BACK              '9
Global Int32 ERROR_FLAG                 '10                             
Global Int32 ERROR_TYPE                 '11
Global Int32 ERROR_NUM                  '12
Global Int32 MOTION_INIT_DONE           '13
Global Int32 MOTION_EXECUTED            '14
Global Int32 IO_UPDATE_REQUEST          '15
Global Int32 MOTION_STARTED             '16
Global Int32 MOTION_FINISHED            '17
Global Int32 MOTION_REQUESTED           '18
Global Int32 TSR1_STATUS                '19
Global Int32 TSR2_STATUS                '20
Global Int32 TSR3_STATUS                '21
Global Int32 TSR4_STATUS                '22
Global Int32 TSR5_STATUS                '23
Global Int32 TSR6_STATUS                '24
Global Int32 DESIRED_SPEED              '25
Global Int32 RECVCONN_STATUS            '26
Global Int32 SENDCONN_STATUS            '27
Global Int32 NM_UPDATE_REQUEST          '28

Global Int32 TSR1_REQUEST_STATUS        '29
Global Int32 TSR2_REQUEST_STATUS        '30
Global Int32 TSR3_REQUEST_STATUS        '31
Global Int32 TSR4_REQUEST_STATUS        '32
Global Int32 TSR5_REQUEST_STATUS        '33
Global Int32 TSR6_REQUEST_STATUS        '34


'Global Int32 WAIT_IO_INDEX             old one
Global Int32 WAIT_IO_INDEX              '0
Global Int32 WAIT_IO_VALUE              '1
Global Int32 WAIT_IO_ARRAY(100)         'new

'============S-Variable==================
Global String IO_UPDATE_CMD$              '30
Global String MOTION_RESPONSE$            '31
Global String POSITION_ID$                '32
Global String DEV_MODEL$                  '33
Global String DEV_OS_VER$                 '34
Global String DEV_SERIAL_NUM$             '35   note: not exist in Epson
Global String NM_UPDATE_CMD$              '36

Global String RECV_QUEUE$(50)
Global String SEND_QUEUE$(50)
Global String MOTION_QUEUE$(1500)
Global String QUEUE_PUSH_TEMP$(30)
Global String NM_QUEUE$(600)
Global String MOTION_CMD$(30)
Global String NM_CMD$(30)

Global String PARSE_CMD_TEMP$(30)

'============F-Variable================== note: single not exist in Epson
Global Double LAST_STOP_POSITION_X       '0
Global Double LAST_STOP_POSITION_Y       '1
Global Double LAST_STOP_POSITION_Z       '2
Global Double LAST_STOP_POSITION_U       '3`
Global Double LAST_STOP_POSITION_V       '4
Global Double LAST_STOP_POSITION_W       '5
Global Double LAST_STOP_POSITION_J8      '6     note: called j8 in Epson

'============ErrorHandling==================
Global String ErrorHandling$(3,8)