'!TITLE "Motion Task"

#include "Public.inc"
#include "ErrorHandling.prg"
#include "Queue.prg"

'#Pragma Optimize("wait-idline-time", TIMEOUT_TK_IDLE)	'per Wait 100ms

String cmd_response_string$
Int32 loop_count 
String error_messages$(ERRORMESSAGE_UPPER_LIMIT,ERRORMESSAGE_UPPER_LIMIT )
String command_id$
String command_name$
String command_raw$
Int32 command_args_count
String temp_string$
String move_args$(ARGS_UPPER_LIMIT)                     'note: change variant to string_size

Function Main
	Call ErrorHandling( error_messages$ )

	Do While 1
        If MOTION_REQUESTED = 1 Then
            MOTION_STARTED = 1
			MOTION_FINISHED = 0
            MOTION_RESPONSE$ = ""
            MOTION_REQUESTED = 0

            command_id$ = MOTION_CMD$(MOTION_CMD_START)         
            command_name$ = MOTION_CMD$(MOTION_CMD_START + 1)
            command_raw$ = MOTION_CMD$(MOTION_CMD_START + 2)
            command_args_count = Val(MOTION_CMD$(MOTION_CMD_START + 3))

            If command_name$ = "MV" Then
                Call MoveAction()
            ElseIf command_name$ = "SM" Then
                Wait Motioncomplete                                               'todo: check if Motioncomplete exist in Epson, and what is "SM"
    			WaitPos
                cmd_response_string$ = command_raw$ + "," + error_messages$(0,0)
            ElseIf command_name$ = "SS" Then
                Call SetSpeed()
            ElseIf command_name$ = "QS" Then
                Call QuerySpeed()
            ElseIf command_name$ = "QP" Then
                Call QueryPosition()
            ElseIf command_name$ = "QCD" Then
                Call QueryCoordinate()
            Else
                Call UnknownCmd()
            EndIf

			MOTION_RESPONSE$ = cmd_response_string$
            MOTION_FINISHED = 1
		ElseIf RECVCONN_STATUS = 0 Or SENDCONN_STATUS = 0 Then                      'todo: rework eth Communication part and change this
			Wait 0.005
		EndIf
	Loop

Fend
'---------- Function ----------
Function MoveAction () As String
    Int32 string_size  = 0
    Int32 pos_of_colon  = 0
    Int32 pos_id  = 0
    Int32 tool_num  = 0
    Int32 speed_value  = 0
    Int32 accel_value  = 0
    Int32 accuracy_value  = 0
    String shift_position_id$  = ""
    Int32 loop_count2  = 1
    Int32 shift_parsing_done_flag  = 0
    String temp_parsing_string$  = ""
    Int32 temp_parsing_size  = 0
    Int32 check_index  = 0
    String temp_shift_string$  = ""
    Int32 pos_of_add_minus  = 0
    Int32 shift_size = 0
    String shift_coordinate$  = ""
    Double shift_value = 0
    Double shift_x = 0                                  
    Double shift_y = 0
    Double shift_z = 0
    Double shift_u = 0
    Double shift_v = 0
    Double shift_w = 0
    Double shift_j8 = 0      
    'Dim shift_position As Position                                   note: SHIFT_POSITION->P101
    P101 =  XY(0, 0, 0, 0, 0, 0) :S(0)                           
    String accuracy_type$  = ""

	If command_args_count < 1 Then
		Goto MOVE_CNT_E
	EndIf


	DO While loop_count2 <= command_args_count
		loop_count = 1
		temp_string$ = MOTION_CMD$(MOTION_CMD_START + 3 + loop_count2)         
		MOVE_SPLIT:
        string_size = Len(temp_string$)
        If string_size > 0 Then
            pos_of_colon = InStr(temp_string$,":")
            If pos_of_colon > 0 And pos_of_colon <= string_size Then
                move_args$(loop_count) = Left$(temp_string$,pos_of_colon - 1)
                loop_count = loop_count + 1
                temp_string$ = Right$(temp_string$,string_size - pos_of_colon)
                Goto MOVE_SPLIT
            Else
                move_args$(loop_count) = temp_string$
            EndIf
        Else
            Goto MOVE_INVALID
        EndIf
        shift_x = 0.0
        shift_y = 0.0
        shift_z = 0.0
        shift_u = 0.0
        shift_v = 0.0
        shift_w = 0.0
        SHIFT_POSITION = XY(0,0,0,0,0,0,CurFig) :S(0)         'note: use P101 here, s axis may not be necessary

        If loop_count >= 6 Then
           '1->position, 2->coordinate system, 3->tool, 4->speed, 5->accel
           '6->accuracy, 7->SM level, 8->move type, 9->shift
           If move_args$(1) = "*" Then
               pos_id = 0
           Else
               pos_id = Val(move_args$(1))
           EndIf
           tool_num = Val(move_args$(3))
           speed_value = Val(move_args$(4))
           accel_value = Val(move_args$(5))
           accuracy_value = Val(move_args$(6))
          If accuracy_value <= 0 And accel_value > 100 Then
              Goto MOVE_INVALID
          EndIf
           If accel_value <= 0 And accel_value > 100 Then
               Goto MOVE_INVALID
           EndIf
           If speed_value <=0 Or speed_value > 100 Then
               Goto MOVE_INVALID
           EndIf
           DESIRED_SPEED = speed_value
           SpeedFactor DESIRED_SPEED               

           If loop_count >= 9 And Len(move_args$(9)) > 0 Then
                shift_position_id$ = Str$(pos_id) + ":" + move_args$(9)
                shift_parsing_done_flag = 0
                temp_parsing_string$ = move_args$(9)
                SHIFT_LOOP:
                temp_parsing_size = Len(move_args$(9))
                check_index = InStr(temp_parsing_string$,"&")
                If check_index > 0 And check_index <= temp_parsing_size Then
                    temp_shift_string$ = Left$(temp_parsing_string$,check_index - 1)
                    temp_parsing_string$ = Right$(temp_parsing_string$,temp_parsing_size - check_index)
                Else
                    temp_shift_string$ = temp_parsing_string$
                    temp_parsing_string$ = ""
                    shift_parsing_done_flag = 1
                EndIf
                pos_of_add_minus = InStr(temp_shift_string$,"+")
                shift_size = Len(temp_shift_string$)
                If pos_of_add_minus > 0 And pos_of_add_minus <= shift_size Then
                    shift_coordinate$ = Left$(temp_shift_string$,pos_of_add_minus - 1)
                    shift_value = Val(Right$(temp_shift_string$,shift_size - pos_of_add_minus))
                Else
                    pos_of_add_minus = InStr(temp_shift_string$,"-")
                    If pos_of_add_minus > 0 And pos_of_add_minus <= shift_size Then
                        shift_coordinate$ = Left$(temp_shift_string$,pos_of_add_minus - 1)
                        shift_value = 0 - Val(Right$(temp_shift_string$,shift_size - pos_of_add_minus))
                    EndIf
                EndIf
                If shift_coordinate$ = "X" Then
                    shift_x = shift_x + shift_value
                ElseIf shift_coordinate$ = "Y" Then
                    shift_y = shift_y + shift_value
                ElseIf shift_coordinate$ = "Z" Then
                    shift_z = shift_z + shift_value
                ElseIf shift_coordinate$ = "U" Then
                    shift_u = shift_u + shift_value
                ElseIf shift_coordinate$ = "V" Then
                    shift_v = shift_v + shift_value
                ElseIf shift_coordinate$ = "W" Then
                    shift_w = shift_w + shift_value
                ElseIf shift_coordinate$ = "J8" Then
                    shift_j8 = shift_j8 + shift_value                   
                EndIf
                If shift_parsing_done_flag = 1 Then
                    P101 = (shift_x,shift_y,shift_z,shift_u,shift_v,shift_w) :S(shift_j8)
                    Goto SHIFT_END
                Else
                    Goto SHIFT_LOOP
                EndIf
                SHIFT_END:
           Else
                shift_position_id$ = Str$(pos_id)
           EndIf
        Else
            Goto MOVE_INVALID
        EndIf
        POSITION_ID$ = POSITION_ID$ + "~" + shift_position_id$
        If accuracy_value <= 80 Then
            accuracy_type$ = "@P"
        ElseIf accuracy_value >80 And accuracy_value <= 90 Then
            accuracy_type$ = "@0"
        ElseIf accuracy_value >90 And accuracy_value <= 95 Then
            accuracy_type$ = "@E"
        ElseIf accuracy_value >95 And accuracy_value <= 100 Then
            accuracy_type$ = "@C"
        EndIf

		Motor On
		'TAKEARM 1                   todo: check if takearm exits in Epson
        TLSet tool_num              'todo: may be difference

        If move_args$(8) = "L" Then                 'todo: where does NEXT in the end of MOVE cmd jump to?
            Speeds 100                              'note: this line may be unnecessary
            Accels accel_value
            Move SHIFT_POSITION            
        ElseIf move_args$(8) = "P" Then
            Speeds 100   
            Accels accel_value
            Go SHIFT_POSITION
        Else
            Goto MOVE_INVALID
        EndIf
		'ARRIVE 100                         'todo: does waitPos equals to arrive 100?
        WaitPos                         
        POSITION_ID$ = shift_position_id$
        MOTION_EXECUTED = 1
        loop_count2 = loop_count2 + 1
    Loop

    MOVE_SUCCESS:
	'Wait Motioncomplete                                                 todo: check if Motioncomplete exist in Epson/ use WaitPos?
    cmd_response_string$ = command_raw$ + "," + error_messages$(0,0)
    Goto MOVE_END

    MOVE_INVALID:
    ERROR_FLAG = 1
    ERROR_TYPE = 2
    ERROR_NUM = 1
    cmd_response_string$ = command_raw$ + "," + error_messages$(ERROR_TYPE,ERROR_NUM)
    Goto MOVE_END

    MOVE_CNT_E:
    ERROR_FLAG = 1
    ERROR_TYPE = 2
    ERROR_NUM = 2
    cmd_response_string$ = command_raw$ + "," + error_messages$(ERROR_TYPE,ERROR_NUM)
    Goto MOVE_END

    MOVE_END:

Fend

Function QueryPosition() As String
	String temp_position$ = ""
	String temp_sting$ = ""
	Int32 temp_cut = 0

    temp_string$ = Str$(CX(RealPos))
    temp_cut = InStr(temp_sting$, ".")                          
    If temp_cut > 0 And temp_cut <= Len(temp_string$) Then
        temp_string$ = Left$(temp_sting$, temp_cut + 1)
    EndIf
    temp_position$ = temp_string$

    temp_string$ = Str$(CY(RealPos))
    temp_cut = InStr(temp_sting$, ".")
    If temp_cut > 0 And temp_cut <= Len(temp_string$) Then
        temp_string$ = Left$(temp_sting$, temp_cut + 1)
    EndIf
    temp_position$ = temp_position$ + "&" + temp_string$

    temp_string$ = Str$(CZ(RealPos))
    temp_cut = InStr(temp_sting$, ".")
    If temp_cut > 0 And temp_cut <= Len(temp_string$) Then
        temp_string$ = Left$(temp_sting$, temp_cut + 1)
    EndIf
    temp_position$ = temp_position$ + "&" + temp_string$

    temp_string$ = Str$(CU(RealPos))
    temp_cut = InStr(temp_sting$, ".")
    If temp_cut > 0 And temp_cut <= Len(temp_string$) Then
        temp_string$ = Left$(temp_sting$, temp_cut + 1)
    EndIf
    temp_position$ = temp_position$ + "&" + temp_string$

    temp_string$ = Str$(CV(RealPos))
    temp_cut = InStr(temp_sting$, ".")
    If temp_cut > 0 And temp_cut <= Len(temp_string$) Then
        temp_string$ = Left$(temp_sting$, temp_cut + 1)
    EndIf
    temp_position$ = temp_position$ + "&" + temp_string$

    temp_string$ = Str$(CW(RealPos))
    temp_cut = InStr(temp_sting$, ".")
    If temp_cut > 0 And temp_cut <= Len(temp_string$) Then
        temp_string$ = Left$(temp_sting$, temp_cut + 1)
    EndIf
    temp_position$ = temp_position$ + "&" + temp_string$

    temp_string$ = Str$(CS(RealPos))                                        
    temp_cut = InStr(temp_sting$, ".")
    If temp_cut > 0 And temp_cut <= Len(temp_string$) Then
        temp_string$ = Left(temp_sting$, temp_cut + 1)
    EndIf
    temp_position$ = temp_position$ + "&" + temp_string$


	POSITION_ID$ = LTrim$(POSITION_ID$)
	POSITION_ID$ = RTrim$(POSITION_ID$)
	If command_args_count = 0 Then
		cmd_response_string$ = command_id$ +  "," + "RP" + "," + POSITION_ID$ + "," + temp_position$ + "," + error_messages$(0,0)
	Else
		cmd_response_string$ = command_id$ +  "," + "RP" + "," + "P" + "," + POSITION_ID$ + "," + temp_position$ + "," + error_messages$(0,0)
	EndIf
Fend

Function QueryCoordinate() As String
    String temp_reply_message$  = ""
    Int32 temp_coordinate  = 0
	String temp_cmd_response_string$  = ""
    If command_args_count <= 0 Then
        Goto QC_CNT_E
    EndIf

    FOr loop_count = 1 To command_args_count - 1  Step 2                'todo: dont understand what this function's purpose
        temp_coordinate = Val(MOTION_CMD$(MOTION_CMD_START + 4 + loop_count))         
        If temp_coordinate < 0 Then
            Goto QC_INVALID
        EndIf                                      
        temp_reply_message$ = temp_reply_message$ + "P" + "," + Str$(temp_coordinate) + "," + Str$(CX(P(temp_coordinate))) + "&" + Str$(CY(P(temp_coordinate))) + "&" + Str$(CZ(P(temp_coordinate))) + "&" + Str$(CU(P(temp_coordinate))) + "&" + Str$(CV(P(temp_coordinate))) + "&" + Str$(CW(P(temp_coordinate))) + "&" + Str$(CS(temp_coordinate))) + ","
		
    Next

    QC_SUCCESS:
    cmd_response_string$ = command_id$ +  "," + "RCD" +"," + temp_reply_message$ + error_messages$(0,0)
    Goto QC_END

    QC_INVALID:
    ERROR_TYPE = 2
    ERROR_NUM = 1
    cmd_response_string$ = command_raw$ + "," + error_messages$(ERROR_TYPE,ERROR_NUM)
    Goto QC_END

    QC_CNT_E:
    ERROR_TYPE = 2
    ERROR_NUM = 2
    cmd_response_string$ = command_raw$ + "," + error_messages$(ERROR_TYPE,ERROR_NUM)
    Goto QC_END

    QC_END:

Fend

Function QuerySpeed() As String
    Int32 current_speed = 0
    current_speed = SpeedFactor                  
	cmd_response_string$ = command_id$ +  "," + "RS" +  "," + Str$(current_speed) + "," + error_messages$(0,0)
Fend

Function SetSpeed() As String
    Int32 speed_arg  = 0
    If command_args_count <> 1 Then
        Goto SS_CNT_E
    EndIf
    speed_arg = Val(MOTION_CMD$(MOTION_CMD_START + 4))           
    If speed_arg <= 0 Or speed_arg > 100 Then
        Goto SS_INVALID
    EndIf
    DESIRED_SPEED = speed_arg
    SpeedFactor DESIRED_SPEED                   

    SS_SUCCESS:
 	cmd_response_string$ = command_id$ +  "," + "RS" +  "," + Str$(DESIRED_SPEED) + "," + error_messages$(0,0)
    Goto SS_END

    SS_INVALID:
    ERROR_TYPE = 2
    ERROR_NUM = 1
    cmd_response_string$ = command_raw$ + "," + error_messages$(ERROR_TYPE,ERROR_NUM)
    Goto SS_END

    SS_CNT_E:
    ERROR_TYPE = 2
    ERROR_NUM = 2
    cmd_response_string$ = command_raw$ + "," + error_messages$(ERROR_TYPE,ERROR_NUM)
    Goto SS_END

    SS_END:
Fend

Function UnknownCmd() As String
	cmd_response_string$ = command_raw$ + "," + error_messages$(0,0)
Fend