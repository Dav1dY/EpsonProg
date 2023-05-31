'!TITLE "Execute Motion CommAnd Task"

#include "Public.inc"
#include "ErrorHandling.prg"   ' todo: maybe cannot include a .prg file or no need to include
#include "Queue.prg"

String cmd_response_string$ = ""
Int32 loop_count
String command_id$ = ""1
String command_name$ = ""
String command_raw$ = ""
Int32 command_args_count = 0
String nm_args$(ARGS_UPPER_LIMIT)
String error_messages$(ERRORMESSAGE_UPPER_LIMIT,ERRORMESSAGE_UPPER_LIMIT)

Function Main

    Call ErrorHandling$(error_messages$)                         'todo: may define as a global string array later
    
    Int32 count1 = 0
    Int32 cmd_args_limit_count
    cmd_args_limit_count = ARGS_UPPER_LIMIT - 4

    TSR1_STATUS = 1
	Do While 1
		START:
        If TSR1_STATUS <> TSR1_REQUEST_STATUS Then
            TSR1_STATUS = TSR1_REQUEST_STATUS
        EndIf
        If TSR1_STATUS = 0 Then
            Wait 0.1
			If CHECK_TASK_STATE(TSR0) Then
				TSR1_REQUEST_STATUS = 1
			EndIf
            Goto START
        EndIf
        POP:
		If MOTION_FRONT - MOTION_BACK <> 0 Then ' queue is not empty
			Call PopMotionCmdQueue()
            
            command_id$ = MOTION_CMD$(MOTION_CMD_START)                     
            command_name$ = MOTION_CMD$(MOTION_CMD_START + 1)
            command_raw$ = MOTION_CMD$(MOTION_CMD_START + 2)
            command_args_count = Val(MOTION_CMD$(MOTION_CMD_START + 3))
            
			If command_args_count > 0 And command_args_count <= cmd_args_limit_count Then
			    count1 = 1
                Do While (count1 <= command_args_count)
                    nm_args$(count1) = MOTION_CMD$(MOTION_CMD_START + 3 + count1)
                    count1 = count1 + 1
                Loop
            EndIf

            If command_args_count < 0 Then
                Call InvalidCmd()
            ElseIf command_args_count > cmd_args_limit_count Then
                Call ArgsCountExceed()
            Else
                If command_name$ = "MV" Or command_name$ = "SM" Or command_name$ = "SS" Or command_name$ = "QS" Or command_name$ = "QP" Or command_name$ = "QCD" Then
                    Call RequestMotion()
                ElseIf command_name$ = "WI" Then
                    If ERROR_FLAG <> 0 Then
                        Call ErrorState()
                    Else
                        Call WaitInput()
                    EndIf
                ElseIf command_name$ = "SO" Then
                    If ERROR_FLAG <> 0 Then
                        Call ErrorState()
                    Else
                        Call SetOutput()
                    EndIf
                ElseIf command_name$ = "CI" Then
                    If ERROR_FLAG <> 0 Then
                        Call ErrorState()
                    Else
                        Call CheckInput()
                    EndIf
                ElseIf command_name$ = "DL" Then
                    If ERROR_FLAG <> 0 Then
                        Call ErrorState()
                    Else
                        Call DelaySecs()
                    EndIf
                ElseIf command_name$ = "CE" Then
                    Call ClearError()
                ElseIf command_name$ = "QE" Then
                    Call QueryError()
                ElseIf command_name$ = "QIO" Then
                    Call QueryIo()
                ElseIf command_name$ = "QIOM" Then
                    Call QueryIoMapping()
                ElseIf command_name$ = "QC" Then
                    Call QueryConfig()
                Else
                    Call UnknownCmd()
                EndIf
            EndIf

			Call PushCmdSendQueue(cmd_response_string$)

		Else
			Wait 0.001
		EndIf
	Loop
Fend


'---------- Function ----------
Function RequestMotion() As String
    If ERROR_FLAG <> 0 Then
        Call ErrorState()
    ElseIf MOTION_STARTED = 1 And MOTION_FINISHED = 0 Then
        Call MotionOnGoing()
    ElseIf CHECK_TASK_STATE(RobotTask) Then
        Call ProgramNotRunning()
    Else
        Call RunMotion()
    EndIf
Fend

Function RunMotion() As String
    MOTION_REQUESTED = 1

    Do Until MOTION_REQUESTED = 0 Or (Stat(0) And AUTOMATION_MODE) <> AUTOMATION_MODE Or CHECK_TASK_STATE(RobotTask) Or MOTION_INIT_DONE = 0
        Wait 0.01                                                    
    Loop

    If MOTION_INIT_DONE = 0 Then
        Call MotionInit()
    ElseIf MOTION_REQUESTED = 0 And MOTION_STARTED = 1 Then
        Do While 1
            If CHECK_TASK_STATE(RobotTask) Or (Stat(0) And AUTOMATION_MODE) <> AUTOMATION_MODE Then
                Call ProgramStopped()
                Exit Do
            ElseIf MOTION_INIT_DONE = 0 Then
                Call MotionInit()
            ElseIf MOTION_FINISHED = 1 Then
                cmd_response_string$ = MOTION_RESPONSE$
                Exit Do
            EndIf
            Wait 0.005
        Loop
    Else
        Call ProgramStopped()
    EndIf
    MOTION_REQUESTED = 0
Fend

Function QueryIo() As String             
	Int32 io_value_input
	Int32 io_total_input
	Int32 io_count_input
	Int32 io_value_output
	Int32 io_total_output
	Int32 io_count_output
	String input_string$
	String output_string$

	For io_count_input = PARALLEL_IO_INPUT_START To PARALLEL_IO_INPUT_END Step 8   
		io_value_input = In(io_count_input)
		input_string$ = Hex$(io_value_input) + input_string$
	Next

	For io_count_input = PARALLEL_IO_INPUT_START To PARALLEL_IO_INPUT_END Step 8      
		io_value_input = Out(io_count_input)
		input_string$ = Hex$(io_value_input) + input_string$
	Next
	cmd_response_string$ = command_id$  + "," + "UIO" + "," + input_string$ + "," + output_string$ + "," + error_messages$(0,0)
Fend

Function SetOutput() As String
    Int32 set_output_index = 0
    Int32 expected_value = 0
	If command_args_count < 2 Or command_args_count Mod 2 <> 0 Then
	    Goto SO_CNT_E
	EndIf
	loop_count = 2
	Do While loop_count <= command_args_count
        set_output_index = Val(nm_args$(loop_count - 1) + PARALLEL_IO_OUTPUT_START)
        If set_output_index >= PARALLEL_IO_OUTPUT_START And set_output_index <= PARALLEL_IO_OUTPUT_END Then
            expected_value = Val(nm_args$(loop_count))
            If expected_value = 1 Then
                On set_output_index                     
            Else
                Off set_output_index
			EndIf
        ElseIf (set_output_index >= MINI_IO_OUTPUT_START And set_output_index <= MINI_IO_OUTPUT_END) Or (set_output_index >= HAND_IO_OUTPUT_START And set_output_index <= HAND_IO_OUTPUT_END) Then
            Goto SO_INVALID
        Else
            Goto SO_INDEX_E
        EndIf
        loop_count = loop_count + 2
	Loop
	cmd_response_string$ = command_raw$ + "," + error_messages$(0,0)
	Goto SO_END

	SO_ERROR:
    ERROR_FLAG = 1
    ERROR_TYPE = 3
    ERROR_NUM = 1
    cmd_response_string$ = command_raw$ + "," + error_messages$(ERROR_TYPE,ERROR_NUM)
	Goto SO_END

	SO_INDEX_E:
    ERROR_FLAG = 1
    ERROR_TYPE = 2
    ERROR_NUM = 4
    cmd_response_string$ = command_raw$ + "," + error_messages$(ERROR_TYPE,ERROR_NUM)
	Goto SO_END

    SO_INVALID:
    ERROR_FLAG = 1
    ERROR_TYPE = 2
    ERROR_NUM = 1
    cmd_response_string$ = command_raw$ + "," + error_messages$(ERROR_TYPE,ERROR_NUM)	
	Goto SO_END

    SO_CNT_E:
    ERROR_FLAG = 1
    IRROR_TYPE = 2
    ERROR_NUM = 2
    cmd_response_string$ = command_raw$ + "," + error_messages$(ERROR_TYPE,ERROR_NUM)	
	Goto SO_END

    SO_END:
Fend

Function WaitInput() As String
    Double running_secs = 0     'todo: change single to double
    Int32 wait_result = 0
    Int32 timeout_flag = 0
    Int32 wait_input_args_count = 0
    Double timeout_secs = 0
    String header_string$ = ""
    String message_string$ = ""
    Int32 reply_index = 0
    Int32 present_value = 0
    Double use_secs = 0
    Int32 error_enabled = 0

    running_secs = Time(2)
    wait_result = 1
    timeout_flag = 0
    wait_input_args_count = command_args_count -2
    If wait_input_args_count < 2 Or wait_input_args_count MOD 2 <> 0 Then
        Goto WI_CNT_E
    EndIf
    timeout_secs = Val(nm_args$(1))
    header_string$ = nm_args$(1) + "," + nm_args$(2) + ","
    loop_count = 2
    Do While loop_count <= wait_input_args_count                                                   
        WAIT_IO_ARRAY(WAIT_IO_INDEX + loop_count) = Val(nm_args$(loop_count + 1) + PARALLEL_IO_INPUT_START)
        WAIT_IO_ARRAY(WAIT_IO_VALUE + loop_count) = Val(nm_args$(loop_count + 2)) 
        If (WAIT_IO_ARRAY(WAIT_IO_INDEX + loop_count) >= MINI_IO_INPUT_START And WAIT_IO_ARRAY(WAIT_IO_INDEX + loop_count) <= MINI_IO_INPUT_END) Or (I[WAIT_IO_INDEX + loop_count] >= HAND_IO_INPUT_START And I[WAIT_IO_INDEX + loop_count] <= HAND_IO_INPUT_END) Or (I[WAIT_IO_INDEX + loop_count] >= PARALLEL_IO_INPUT_START And I[WAIT_IO_INDEX + loop_count] <= PARALLEL_IO_INPUT_END) Then

        Else
            Goto WI_INDEX_E
        EndIf
        loop_count = loop_count + 2
    Loop
    Do While 1
        wait_result = 1
        message_string$ = header_string$
        loop_count = 2
        Do While loop_count <= wait_input_args_count
            reply_index = loop_count + 1
            present_value = In(WAIT_IO_INDEX + loop_count)                                     
            If present_value <> WAIT_IO_ARRAY(WAIT_IO_VALUE + loop_count) Then
                message_string$ = message_string$ + nm_args$(reply_index) + "," + Str$(present_value) + ","
                wait_result = 0
                If timeout_flag = 0 Then
                    Exit Do
                EndIf
            Else
                message_string$ = message_string$ + nm_args$(reply_index) + "," + nm_args$(reply_index + 1) + ","
            EndIf
            loop_count = loop_count + 2
        Loop
        If wait_result = 1 Then
            Goto WI_SUCCESS
        ElseIf timeout_flag = 1 Then
            Goto WI_TIMEOUT
        EndIf
        use_secs = Time(2) - running_secs
        If use_secs > timeout_secs Then
            timeout_flag = 1
        ElseIf use_secs < 0 Then
            running_secs = Time(2)
        Else
            Delay 5
        EndIf
    Loop

    WI_SUCCESS:
    cmd_response_string$ = command_raw$ + "," + error_messages$(0,0)
    Goto END_WI

    WI_CNT_E:
    ERROR_FLAG = 1
    IRROR_TYPE = 2
    ERROR_NUM = 2
    cmd_response_string$ = command_raw$ + "," + error_messages$(IRROR_TYPE,ERROR_NUM)
	Goto END_WI

    WI_INDEX_E:
    ERROR_FLAG = 1
    IRROR_TYPE = 2
    ERROR_NUM = 3
    cmd_response_string$ = command_raw$ + "," + error_messages$(IRROR_TYPE,ERROR_NUM)
	Goto END_WI

    WI_TIMEOUT:
    IRROR_TYPE = 3
    ERROR_NUM = 2
    error_enabled = Val(nm_args$(2))
    If error_enabled = 1 Then
        ERROR_FLAG = 1
    EndIf
    cmd_response_string$ = command_id$ + "," + command_name + "," + message_string$ + error_messages$(IRROR_TYPE,ERROR_NUM)
    Goto END_WI

    END_WI:
Fend

Function CheckInput() As String
    Int32 check_result = 0
    Int32 check_input_args_count = 0
    String message_string$ = ""
    Int32 check_index_num = 0
    Int32 check_value_num = 0
    Int32 actual_value = 0
    Int32 check_index = 0
    Int32 check_value = 0
	Int32 error_enabled = 0

    check_result = 1
    check_input_args_count = command_args_count - 1
    If command_args_count < 3 Or check_input_args_count MOD 2 <> 0 Then
        Goto CI_CNT_E
    EndIf
    message_string$ = nm_args$(1) + ","
    loop_count = 2
    Do While loop_count <= check_input_args_count
        check_index_num = loop_count
        check_value_num = check_index_num + 1
        check_index = Val(nm_args$(check_index_num) + PARALLEL_IO_INPUT_START)
        check_value = Val(nm_args$(check_value_num))
        If (check_index >= MINI_IO_INPUT_START And check_index <= MINI_IO_INPUT_END) Or (check_index >= HAND_IO_INPUT_START And check_index <= HAND_IO_INPUT_END) Or (check_index >= PARALLEL_IO_INPUT_START And check_index <= PARALLEL_IO_INPUT_END) Then
            actual_value = In(check_index)                    
        Else
            check_result = 0
            Goto CI_INDEX_E
        EndIf
        If actual_value <> check_value Then
            check_result = 0
            message_string$ = message_string$ + nm_args$(check_index_num) + "," +Str$(actual_value) + ","
        Else
            message_string$ = message_string$ + nm_args$(check_index_num) + "," + nm_args$(check_value_num) + ","
        EndIf
        loop_count = loop_count + 2
    Loop
	If check_result = 1 Then
		Goto CI_SUCCESS
	Else
		Goto CI_FAILED
	EndIf

	CI_SUCCESS:
    cmd_response_string$ = command_raw$ + "," + error_messages$(0,0)
	Goto END_CI

	CI_FAILED:
    IRROR_TYPE = 3
    ERROR_NUM = 3
    error_enabled = Val(nm_args$(1))
    If error_enabled = 1 Then
        ERROR_FLAG = 1
    EndIf
    cmd_response_string$ = command_id$ + "," + "CI" + "," + message_string$ + error_messages$(IRROR_TYPE,ERROR_NUM)
	Goto END_CI

	CI_CNT_E:
	ERROR_FLAG = 1
    IRROR_TYPE = 2
    ERROR_NUM = 2
    cmd_response_string = command_raw$ + "," + error_messages$(IRROR_TYPE,ERROR_NUM)
	Goto END_CI

	CI_INDEX_E:
	ERROR_FLAG = 1
    IRROR_TYPE = 2
    ERROR_NUM = 3
    cmd_response_string$ = command_raw$ + "," + error_messages$(IRROR_TYPE,ERROR_NUM)
	Goto END_CI

	END_CI:
Fend

Function DelaySecs() As String
    Int32 delay_secs = 0
    Int32 use_time = 0
    use_time = 0
    If command_args_count <> 1 Then
        Goto DL_CNT_E
    EndIf
    delay_secs = Val(nm_args$(1)) * 1000
    Do While 1
       Wait 0.1
        use_time = use_time + 100
        If use_time >= delay_secs Then
            Exit Do
        EndIf
    Loop
    DL_SUCCESS:
    cmd_response_string$ = command_raw$ + "," + error_messages$(0,0)
    Goto END_DL

    DL_CNT_E:
    ERROR_FLAG = 1
    IRROR_TYPE = 2
    ERROR_NUM = 2
    cmd_response_string$ = command_raw$ + "," + error_messages$(IRROR_TYPE,ERROR_NUM)
	Goto END_DL

    END_DL:
Fend

Function QueryConfig() As String
	cmd_response_string$ = command_id$ +  "," + "UC" + "," + DEV_VENDER$ + "," + DEV_MODEL$ + "," + DEV_IP$ + "," + DEV_OS_VER$ + "," + DEV_APP_SW$ + "," + DEV_PROTO_VER$ + "," + DEV_SERIAL_NUM$   + "," + error_messages$(0,0)
Fend

Function QueryIoMapping() As String
	String IO_MAP_SETTING$(1)
	Int32 count_di = 0
	Int32 count_do = 0
	count_di = PARALLEL_IO_INPUT_END - PARALLEL_IO_INPUT_START + 1
	count_do = PARALLEL_IO_OUTPUT_END - PARALLEL_IO_OUTPUT_START + 1

	IO_MAP_SETTING(0) = "DI," + "0" + "~" + Str$(count_di - 1) + ",P-Input,I,10," + Str$(PARALLEL_IO_INPUT_START)
	IO_MAP_SETTING(1) = "DO," + Str$(count_di) + "~" + Str$(count_di + count_do - 1) + ",P-Output,O,10," + Str$(PARALLEL_IO_OUTPUT_START)

	String tempIoMapStr$
	tempIoMapStr$ = IO_MAP_SETTING$(0) + "," + IO_MAP_SETTING$(1)
	
	cmd_response_string$ = command_id$ + "," + "UIOM" + "," + tempIoMapStr$ + "," + error_messages$(0,0)
Fend

Function ClearError() As String
	ERROR_FLAG = 0
	IRROR_TYPE = 0
	ERROR_NUM = 0
    cmd_response_string$ = command_id$ + "," + "CE" + "," + error_messages$(0,0)
Fend

Function QueryError() As String
	If ERROR_FLAG = 0 Then
		cmd_response_string$ = command_id$ + "," + "RE" + "," + error_messages$(0,0)
	Else
		cmd_response_string$ = command_id$ + "," + "RE" + "," + error_messages$(IRROR_TYPE,ERROR_NUM)
	EndIf
Fend

Function ProgramStopped() As String
    If (Stat(0) And SYS_ESTOP) = SYS_ESTOP  Then
        Call ProgramStoppedEStop()
    ElseIf (Stat(0) And AUTOMATION_MODE) <> AUTOMATION_MODE Then
        Call ProgramStoppedManualMode()
    Else
        Call ProgramUnknownError()
    EndIf
Fend

Function ProgramStoppedEStop() As String
    ERROR_FLAG = 1
    IRROR_TYPE = 1
    ERROR_NUM = 1
    cmd_response_string$ = command_raw$ + "," + error_messages$(IRROR_TYPE,ERROR_NUM)
Fend

Function ProgramStoppedManualMode() As String
    ERROR_FLAG = 1
    IRROR_TYPE = 1
    ERROR_NUM = 2
    cmd_response_string$ = command_raw$ + "," + error_messages$(IRROR_TYPE,ERROR_NUM)
Fend

Function ProgramUnknownError() As String
    ERROR_FLAG = 1
    IRROR_TYPE = 1
    ERROR_NUM = 4
    cmd_response_string$ = command_raw$ + "," + error_messages$(IRROR_TYPE,ERROR_NUM)
Fend

Function ProgramNotRunning() As String
    ERROR_FLAG = 1
    IRROR_TYPE = 1
    ERROR_NUM = 5
    cmd_response_string$ = command_raw$ + "," + error_messages$(IRROR_TYPE,ERROR_NUM)
Fend

Function ErrorState() As String
    ERROR_FLAG = 1
    IRROR_TYPE = 1
    ERROR_NUM = 6
    cmd_response_string$ = command_raw$ + "," + error_messages$(IRROR_TYPE,ERROR_NUM)
Fend

Function MotionOnGoing() As String
    ERROR_FLAG = 1
    IRROR_TYPE = 1
    ERROR_NUM = 7
    cmd_response_string$ = command_raw$ + "," + error_messages$(IRROR_TYPE,ERROR_NUM)
Fend

Function MotionInit() As String
    ERROR_FLAG = 1
    IRROR_TYPE = 1
    ERROR_NUM = 8
    cmd_response_string$ = command_raw$ + "," + error_messages$(IRROR_TYPE,ERROR_NUM)
Fend

Function UnknownCmd() As String
    ERROR_FLAG = 1
    IRROR_TYPE = 2
    ERROR_NUM = 5
    cmd_response_string$ = command_raw$ + "," + error_messages$(IRROR_TYPE,ERROR_NUM)
Fend

Function ArgsCountExceed() As String
    ERROR_FLAG = 1
    ERROR_TYPE = 2
    ERROR_NUM = 6
    cmd_response_string$ = command_raw$ + "," + error_messages$(ERROR_TYPE,ERROR_NUM)
Fend

Function InvalidCmd() As String
    ERROR_FLAG = 1
    ERROR_TYPE = 2
    ERROR_NUM = 7
    cmd_response_string$ = command_raw$ + "," + error_messages$(ERROR_TYPE,ERROR_NUM)
Fend