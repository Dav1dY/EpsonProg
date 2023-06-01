'!TITLE "Command parsing task"

#include "Public.inc"
#include "ErrorHandling.prg"
#include "Queue.prg"

String completed_cmd_string$
Int32 pasered_count 
Int32 args_count 
String cmd_id$ 
String cmd_name$ 
Int32 cmd_fields_limit_count
Int32 cmd_args_limit_count

Function Main
	cmd_fields_limit_count = ARGS_UPPER_LIMIT - 2
	cmd_args_limit_count = ARGS_UPPER_LIMIT - 4
    TSR5_STATUS = 1
	Do While 1
		START:
        If TSR5_STATUS <> TSR5_REQUEST_STATUS Then
            TSR5_STATUS = TSR5_REQUEST_STATUS
        EndIf
        If TSR5_STATUS = 0 Then
            Wait 0.1
			If CHECK_TASK_STATE(TSR0) Then
				TSR5_REQUEST_STATUS = 1
			EndIf
            GOTO START
        EndIf

        POP:
		If CMD_RECV_FRONT - CMD_RECV_BACK <> 0 Then ' queue is not empty
            completed_cmd_string$ = PopCmdRecvQueue()
			Call ParseCmd()
			GOTO POP
	    Else
			Wait 0.005
		EndIf
	Loop
Fend

'---------- Sub ----------


Function ParseCmd()                                                                    

	String temp_handling_string$ 	'completed_cmd_string
	Int32 pos_of_comma 				'L2% started from 0
	Int32 agrs_index
	agrs_index = 4
	Int32 string_size
	String left_temp_string$

	temp_handling_string$ = completed_cmd_string$
	pasered_count = 0

	L_START:
	string_size = Len(temp_handling_string$)
	If (string_size > 0) Then
		pos_of_comma = InStr(temp_handling_string$,",")
		If(pos_of_comma > 0 And pos_of_comma <= string_size) Then
			PARSE_CMD_TEMP$(pasered_count) = Left$(temp_handling_string$, pos_of_comma - 1)
			pasered_count = pasered_count + 1
			If(pasered_count >= cmd_fields_limit_count) Then			
			    pasered_count = pasered_count + 1
				GOTO L_END
			Else
				temp_handling_string$ = Right$(temp_handling_string$, string_size - pos_of_comma)
				GOTO L_START
			EndIf
		Else
			PARSE_CMD_TEMP$(pasered_count) = temp_handling_string$
			pasered_count = pasered_count + 1
			GOTO L_END
		EndIf
	EndIf

	L_END:
	cmd_id$ = PARSE_CMD_TEMP$(0)
    cmd_name$ = PARSE_CMD_TEMP$(1)
    args_count = pasered_count - 2

	If Len(cmd_name$) > 3 And Left$(cmd_name$,3) = "NM_" Then
		cmd_name$ = Right$(cmd_name$, Len(cmd_name$) - 3)
		Call PushNonMotionCmdQueue(cmd_id$,cmd_name$,completed_cmd_string$,args_count)
	Else
    	Call PushMotionCmdQueue(cmd_id$,cmd_name$,completed_cmd_string$,args_count)
	EndIf

End Sub