'!TITLE "I/O Position Check Task  "
#include "Public.inc"
#include "Queue.prg"
String cmd_response_string$ = ""
String new_input_status$ = ""
String new_output_status$ = ""

Function Main
	String old_input_status$ = ""
	String old_output_status$ = ""
    Int32 previous_run_state = 1
    Int32 current_run_state = 1
    Int32 disconnected = 1
    Int32 reconnected = 0
    Double previous_updated_io_time = 0                      'note: change to double
    Double previous_check_position_time = 0

    TSR2_STATUS = 1
    IO_UPDATE_CMD$ = ""
    IO_UPDATE_REQUEST = 0

    Do while 1
		START:
        If TSR2_STATUS <> TSR2_REQUEST_STATUS Then
            TSR2_STATUS = TSR2_REQUEST_STATUS
        EndIf
        If TSR2_STATUS = 0 Then
            Wait 0.1
			If CHECK_TASK_STATE(TSR0) Then
				TSR2_REQUEST_STATUS = 1
			EndIf
            GOTO START
        EndIf
        If (Time(2) - previous_check_position_time) > 2000 Or (Time(2) - previous_check_position_time) < 0 Then
            previous_check_position_time = Time(2)
            If (Stat(0) And AUTOMATION_MODE) <> AUTOMATION_MODE Or CHECK_TASK_STATE(RobotTask) Then
                current_run_state = 0
                If previous_run_state <> current_run_state And MOTION_EXECUTED = 1 Then
                    LAST_STOP_POSITION_X = CX(RealPos)                   
                    LAST_STOP_POSITION_Y = CY(RealPos)
                    LAST_STOP_POSITION_Z = CZ(RealPos)
                    LAST_STOP_POSITION_U = CU(RealPos)
                    LAST_STOP_POSITION_V = CV(RealPos)
                    LAST_STOP_POSITION_W = CW(RealPos)
					LAST_STOP_POSITION_J8 = CS(RealPos)                  
                    MOTION_EXECUTED = 0
                EndIf
            Else
                current_run_state = 1
            EndIf
            previous_run_state = current_run_state
        EndIf
        Call OutputIo()
        Call InputIo()

        If RECVCONN_STATUS = 0 Or SENDCONN_STATUS = 0 Then				
            disconnected = 1
        Else
            reconnected = disconnected
            disconnected = 0
        EndIf

        If  new_input_status$ <> old_input_status$ Or new_output_status$ <> old_output_status$ Or reconnected Or (Time(2) - previous_updated_io_time) > 5000 Or (Time(2) - previous_updated_io_time) < 0 Then
            If IO_UPDATE_REQUEST = 0 Then
                IO_UPDATE_CMD$ = "00000,UPDATE_IO," + new_input_status$ + "," + new_output_status$ + "," + "0,Success"
				IO_UPDATE_CMD$ = RTrim$(IO_UPDATE_CMD$)
				IO_UPDATE_CMD$ = LTrim$(IO_UPDATE_CMD$)
                IO_UPDATE_REQUEST = 1
                previous_updated_io_time = Time(2)
                old_input_status$ = new_input_status$
                old_output_status$ = new_output_status$
            Else
                'not send out
            EndIf
        Else
            old_input_status$ = new_input_status$
            old_output_status$ = new_output_status$
        EndIf
        reconnected = 0						'todo: same
        Wait 0.05
	Loop
Fend

Function InputIo() As String
	Int32 io_value_input
	'Int32 io_total_input
	Int32 io_count_input
	String input_string$

	For io_count_input = PARALLEL_IO_INPUT_START To PARALLEL_IO_INPUT_END Step 8          'todo: IO_ARRAY useless, change IO and delete this
		io_value_input = In(IO_ARRAY(io_count_input))
		input_string$ = Hex$(io_value_input) + input_string$
	Next

	new_input_status$ = input_string$
Fend

Function OutputIo() As String
	Int32 io_value_output
	'Int32 io_total_output
	Int32 io_count_output
	String output_string$

	For io_count_input = PARALLEL_IO_INPUT_START To PARALLEL_IO_INPUT_END Step 8          'todo: IO_ARRAY useless, change IO and delete this
		io_value_input = Out(IO_ARRAY(io_count_input))
		input_string$ = Hex$(io_value_input) + input_string$
	Next

	new_output_status$ = output_string$
Fend