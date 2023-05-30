'!TITLE "Check TSR Task"
#include Public.inc

Function Main

    Int32 loop_count
    Int32 loop_count2

    Quit RobotTask 

	BG_TASK_COUNT = 5
	
    TSR1_REQUEST_STATUS = 0
    TSR2_REQUEST_STATUS = 0
    TSR3_REQUEST_STATUS = 0
    TSR4_REQUEST_STATUS = 0
    TSR5_REQUEST_STATUS = 0
    TSR6_REQUEST_STATUS = 0

    Wait 1

    If CHECK_TASK_STATE(TSR1) Then                          'note: check if macro can work in this code
        TSR1_STATUS = 0
    EndIf

    If CHECK_TASK_STATE(TSR2) = 0 Then
        TSR1_STATUS = 0
    EndIf

    If CHECK_TASK_STATE(TSR3) = 0 Then
        TSR1_STATUS = 0
    EndIf

    If CHECK_TASK_STATE(TSR4) = 0 Then
        TSR1_STATUS = 0
    EndIf

    If CHECK_TASK_STATE(TSR5) = 0 Then
        TSR1_STATUS = 0
    EndIf

    If CHECK_TASK_STATE(TSR6) = 0 Then
        TSR1_STATUS = 0
    EndIf

    Int32 all_bg_suspend = 1
    SUSPEND_CHECK:
    all_bg_suspend = 1
    If TSR1_STATUS = 1 Or TSR2_STATUS = 1 Or TSR3_STATUS = 1 Or TSR4_STATUS = 1 Or TSR5_STATUS = 1 Or TSR6_STATUS = 1 Then
        all_bg_suspend = 0
    EndIf
    If all_bg_suspend = 0 Then
        Wait 0.01
        Goto SUSPEND_CHECK
    EndIf

    For loop_count = 0 To RECV_QUEUE_UPPER_LIMIT Step 1
        RECV_QUEUE$(loop_count) = ""
    Next

    For loop_count = 0 To SEND_QUEUE_UPPER_LIMIT Step 1
        SEND_QUEUE$(loop_count) = ""
    Next   

    For loop_count = 0 To MOTION_QUEUE_UPPER_LIMIT Step 1
        MOTION_QUEUE$(loop_count) = ""
    Next

    For loop_count = 0 To ARGS_UPPER_LIMIT Step 1       
        MOTION_CMD$(loop_count) = ""
    Next

    For loop_count = 0 To NM_QUEUE_UPPER_LIMIT Step 1       
        NM_QUEUE$(loop_count) = ""
    Next

    For loop_count = 0 To ARGS_UPPER_LIMIT Step 1     
        NM_CMD$(loop_count) = ""
    Next

    DEV_MODEL$ = RobotInfo$(1)
    DEV_OS_VER$ = Str$(CtrlInfo(9))      'special format as number
    DEV_SERIAL_NUM$ = RobotInfo(4)       'note: function not exist in Epson, only have robot serial number

    'init speed
    DESIRED_SPEED = 5
    SpeedFactor DESIRED_SPEED
    
	'init position_id
	String old_pos_id$ = ""
	If POSITION_ID$ = "" Then
		POSITION_ID$ = "NA"
	EndIf
	old_pos_id$ = POSITION_ID$
	POSITION_ID$ = "NA"

    'check position
	Double shift_allowed  = 1.0         
	Int32 last_checkX = 0
	Int32 last_checkY = 0
	Int32 last_checkZ = 0
	Int32 last_checkU = 0
	Int32 last_checkV = 0
	Int32 last_checkW = 0
	Int32 last_checkJ8 = 0

    last_checkX = Abs(CX(RealPos) - LAST_STOP_POSITION_X) < shift_allowed
    last_checkY = Abs(CY(RealPos) - LAST_STOP_POSITION_Y) < shift_allowed
    last_checkZ = Abs(CZ(RealPos) - LAST_STOP_POSITION_Z) < shift_allowed
    last_checkU = Abs(CU(RealPos) - LAST_STOP_POSITION_U) < shift_allowed
    last_checkV = Abs(CV(RealPos) - LAST_STOP_POSITION_V) < shift_allowed
    last_checkW = Abs(CW(RealPos) - LAST_STOP_POSITION_W) < shift_allowed
    last_checkJ8 = Abs(CS(RealPos) - LAST_STOP_POSITION_J8) < shift_allowed          'note : need test on additional axis, need to check if CS(RealPos) is ok

	Int32 home_checkX = 0
	Int32 home_checkY = 0
	Int32 home_checkZ = 0
	Int32 home_checkU = 0
	Int32 home_checkV = 0
	Int32 home_checkW = 0
	Int32 home_checkJ8 = 0

    home_checkX = Abs(CX(RealPos) - CX(P100)) < shift_allowed                      
    home_checkY = Abs(CY(RealPos) - CY(P100)) < shift_allowed
    home_checkZ = Abs(CZ(RealPos) - CZ(P100)) < shift_allowed
    home_checkU = Abs(CU(RealPos) - CU(P100)) < shift_allowed
    home_checkV = Abs(CV(RealPos) - CV(P100)) < shift_allowed
    home_checkW = Abs(CW(RealPos) - CW(P100)) < shift_allowed
    home_checkJ8 = ABS(CS(RealPos) - CS(P100)) < shift_allowed

	Int32 old_checkX = 0
	Int32 old_checkY = 0
	Int32 old_checkZ = 0
	Int32 old_checkU = 0
	Int32 old_checkV = 0
	Int32 old_checkW = 0
	Int32 old_checkJ8 = 0

	Int32 old_pos_id_valid = 0 
	old_pos_id_valid = (old_pos_id$ <> "NA" And InStr(old_pos_id$,"~") = 0 And InStr(old_pos_id$,":") = 0 And InStr(old_pos_id$,"&") = 0)    


	If home_checkX And home_checkY And home_checkZ And home_checkU And home_checkV And home_checkW And home_checkJ8 Then
		POSITION_ID$ = "100"

	ElseIf old_pos_id_valid Then
        old_checkX = Abs(CX(RealPos)) - CX(P(Val(old_pos_id$))) < shift_allowed
        old_checkY = Abs(CY(RealPos)) - CY(P(Val(old_pos_id$))) < shift_allowed
        old_checkZ = Abs(CZ(RealPos)) - CZ(P(Val(old_pos_id$))) < shift_allowed
        old_checkU = Abs(CU(RealPos)) - CU(P(Val(old_pos_id$))) < shift_allowed
        old_checkV = Abs(CV(RealPos)) - CV(P(Val(old_pos_id$))) < shift_allowed
        old_checkW = Abs(CW(RealPos)) - CW(P(Val(old_pos_id$))) < shift_allowed
        old_checkJ8 = Abs(CS(RealPos)) - CS(P(Val(old_pos_id$)))) < shift_allowed

        If old_checkX And old_checkY And old_checkZ And old_checkU And old_checkV And old_checkW And old_checkJ8 Then
            POSITION_ID$ = old_pos_id$
        Else
            POSITION_ID$ = "NA"
        EndIf
    ElseIf last_checkX And last_checkY And last_checkZ And last_checkU And last_checkV And last_checkW And last_checkJ8 Then
        If old_pos_id$ = "NA" Then
            POSITION_I$ = "NA"
        Else
            POSITION_ID$ = old_pos_id$
        EndIf
	EndIf

    'init flag
    MOTION_FRONT = MOTION_QUEUE_START
    MOTION_BACK = MOTION_QUEUE_START
    NM_FRONT = NM_QUEUE_START
    NM_BACK = NM_QUEUE_START
    CMD_RECV_BACK = RECV_QUEUE_START
    CMD_RECV_FRONT = RECV_QUEUE_START
    CMD_SEND_BACK = SEND_QUEUE_START
    CMD_SEND_FRONT = SEND_QUEUE_START

    'motion initialization
    MOTION_EXECUTED = 0
    MOTION_STARTED = 0
    MOTION_FINISHED = 0
    MOTION_RESPONSE$ = ""

    TSR1_REQUEST_STATUS = 1
    TSR2_REQUEST_STATUS = 1
    TSR3_REQUEST_STATUS = 1
    TSR4_REQUEST_STATUS = 1
    TSR5_REQUEST_STATUS = 1
    TSR6_REQUEST_STATUS = 1

	MOTION_INIT_DONE = 1

    Xqt RobotTask

    Do While 1
        Retry:
		If CHECK_TASK_STATE(TSR1) Then
			Quit TSR1
			Xqt TSR1
			Wait TaskState(TSR1) = STATUS_RUN,TIMEOUT_TK_REBOOT
			If CHECK_TASK_STATE(TSR1) Then
				Goto Retry
			EndIf
		EndIf

		If CHECK_TASK_STATE(TSR2) Then
			Quit TSR2
			Xqt TSR2
			Wait TaskState(TSR2) = STATUS_RUN,TIMEOUT_TK_REBOOT
			If CHECK_TASK_STATE(TSR2) Then
				Goto Retry
			EndIf
		EndIf

		If CHECK_TASK_STATE(TSR3) Then
			Quit TSR3
			Xqt TSR3
			Wait TaskState(TSR3) = STATUS_RUN,TIMEOUT_TK_REBOOT
			If CHECK_TASK_STATE(TSR3) Then
				Goto Retry
			EndIf
		EndIf

		If CHECK_TASK_STATE(TSR4) Then
			Quit TSR4
			Xqt TSR4
			Wait TaskState(TSR4) = STATUS_RUN,TIMEOUT_TK_REBOOT
			If CHECK_TASK_STATE(TSR4) Then
				Goto Retry
			EndIf
		EndIf

		If CHECK_TASK_STATE(TSR5) Then
			Quit TSR5
			Xqt TSR5
			Wait Status(TSR5) = STATUS_RUN,TIMEOUT_TK_REBOOT
			If CHECK_TASK_STATE(TSR5) Then
				Goto Retry
			EndIf
		EndIf

		If CHECK_TASK_STATE(TSR6) Then
			Quit TSR6
			Xqt TSR6
			Wait TaskState(TSR6) = STATUS_RUN,TIMEOUT_TK_REBOOT
			If CHECK_TASK_STATE(TSR6) Then
				Goto Retry
			EndIf
		EndIf

		If CHECK_TASK_STATE(RobotTask) And (Stat(0) And AUTOMATION_MODE) = AUTOMATION_MODE And (Stat(0) And SYS_ESTOP) = 0) Then
			Quit RobotTask                                                               'todo: check if AUTOMATION_MODE=running_task
			Xqt RobotTask
			Wait TaskState(RobotTask) = STATUS_RUN,TIMEOUT_TK_REBOOT
			If CHECK_TASK_STATE(RobotTask) Then
				Goto Retry
			EndIf
		EndIf
        Wait 0.1
    Loop
Fend