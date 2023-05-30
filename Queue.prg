'!TITLE "Queue"
#include "Public.inc"

Function Main

Fend

Function PushCmdToRecvQueue (ByVal recv_cmd As String) As String
    RECV_QUEUE$[CMD_RECV_BACK] = recv_cmd
	If CMD_RECV_BACK + 1 >= RECV_QUEUE_UPPER_LIMIT Then
		CMD_RECV_BACK = RECV_QUEUE_START
    Else
        CMD_RECV_BACK = CMD_RECV_BACK + 1
	EndIf
	recv_cmd = ""
Fend

Function PopCmdRecvQueue () As String
    PopCmdRecvQueue = RECV_QUEUE$[CMD_RECV_FRONT]
    RECV_QUEUE$[CMD_RECV_FRONT] = ""
    If CMD_RECV_FRONT + 1 >= RECV_QUEUE_UPPER_LIMIT Then
        CMD_RECV_FRONT = RECV_QUEUE_START
    Else
        CMD_RECV_FRONT = CMD_RECV_FRONT + 1
	EndIf
Fend

Function PushCmdSendQueue(ByVal send_cmd As String) As String
	SEND_QUEUE$[CMD_SEND_BACK] = send_cmd
	If CMD_SEND_BACK + 1 >= SEND_QUEUE_UPPER_LIMIT Then
		CMD_SEND_BACK = SEND_QUEUE_START
    Else
    	CMD_SEND_BACK = CMD_SEND_BACK + 1
	EndIf
	send_cmd = ""
Fend

Function PopCmdSendQueue() As String
    PopCmdSendQueue = SEND_QUEUE$[CMD_SEND_FRONT]
    SEND_QUEUE$[CMD_SEND_FRONT] = ""
    If CMD_SEND_FRONT + 1 >= SEND_QUEUE_UPPER_LIMIT Then
        CMD_SEND_FRONT = SEND_QUEUE_START
    Else
        CMD_SEND_FRONT = CMD_SEND_FRONT + 1
    EndIf
Fend

Function PushMotionCmdQueue(ByVal cmd_id As String,ByVal cmd_name As String,ByVal completed_cmd_string As String,ByVal As Integer) As String
	Int32 loop_index = 0													'note: actually pushing motion queue not motion_cmd
	Int32 cmd_string_size = 0												'note: cmd_string_size unused here
	Int32 args_index = 2
	MOTION_QUEUE$(MOTION_BACK)     = cmd_id                         
	MOTION_QUEUE$(MOTION_BACK + 1) = cmd_name
	MOTION_QUEUE$(MOTION_BACK + 2) = completed_cmd_string
	MOTION_QUEUE$(MOTION_BACK + 3) = Str$(args_count)

	If args_count >= 1 Then
		args_index = 0;
		For loop_index = 1 To args_count Step 1
			cmd_string_size = 3 + loop_index
			MOTION_QUEUE(MOTION_BACK +3 + loop_index) = QUEUE_PUSH_TEMP$(args_index)
			args_index = args_index + 1
		Next
	EndIf

	If MOTION_BACK + ARGS_UPPER_LIMIT >= MOTION_QUEUE_UPPER_LIMIT Then
		MOTION_BACK = MOTION_QUEUE_START
    Else
        MOTION_BACK = MOTION_BACK + ARGS_UPPER_LIMIT
	EndIf
	completed_cmd_string = ""
Fend

Function PopMotionCmdQueue() As String                           
	Int32 loop_count = 0
	Int32 args_count = 0
	MOTION_CMD$(MOTION_CMD_START) = MOTION_QUEUE$(MOTION_FRONT)
	MOTION_CMD$(MOTION_CMD_START + 1) = MOTION_QUEUE$(MOTION_FRONT + 1)
	MOTION_CMD$(MOTION_CMD_START + 2) = MOTION_QUEUE$(MOTION_FRONT + 2)
	MOTION_CMD$(MOTION_CMD_START + 3) = MOTION_QUEUE$(MOTION_FRONT + 3)

	args_count = Val(MOTION_QUEUE$(MOTION_FRONT + 3))
	For loop_count = 1 To args_count Step 1
		MOTION_CMD$(MOTION_CMD_START + 3 + loop_count) = MOTION_QUEUE$(MOTION_FRONT + 3 + loop_count)
	Next

	If MOTION_FRONT + ARGS_UPPER_LIMIT >= MOTION_QUEUE_UPPER_LIMIT Then
		MOTION_FRONT = MOTION_QUEUE_START
    Else
        MOTION_FRONT = MOTION_FRONT + ARGS_UPPER_LIMIT
	EndIf
Fend


Function PushNonMotionCmdQueue(ByVal cmd_id As String,ByVal cmd_name As String,ByVal completed_cmd_string As String,ByVal args_count As Integer) As String
	Int32 loop_index = 0
	Int32 cmd_string_size = 0
	Int32 args_index = 2
	NM_QUEUE$(NM_BACK)     = cmd_id
	NM_QUEUE$(NM_BACK + 1) = cmd_name
	NM_QUEUE$(NM_BACK + 2) = completed_cmd_string
	NM_QUEUE$(NM_BACK + 3) = Str$(args_count)

	If args_count >= 1 Then
	    args_index = 0
		For loop_index = 1 To args_count Step 1
			cmd_string_size = 3 + loop_index
			NM_QUEUE$(NM_BACK +3 + loop_index) = QUEUE_PUSH_TEMP$(args_index)
			args_index = args_index + 1
		Next
	EndIf

	If NM_BACK + ARGS_UPPER_LIMIT >= NM_QUEUE_UPPER_LIMIT Then
		NM_BACK = NM_QUEUE_START
    Else
        NM_BACK = NM_BACK + ARGS_UPPER_LIMIT
	EndIf
	completed_cmd_string = ""
Fend

Function PopNonMotionCmdQueue() As String
	Int32 loop_count = 0
	Int32 args_count = 0
	NM_CMD$(NM_CMD_START) = NM_QUEUE$(NM_FRONT)
	NM_CMD$(NM_CMD_START + 1) = NM_QUEUE$(NM_FRONT + 1)
	NM_CMD$(NM_CMD_START + 2) = NM_QUEUE$(NM_FRONT + 2)
	NM_CMD$(NM_CMD_START + 3) = NM_QUEUE$(NM_FRONT + 3)

	args_count = Val(NM_QUEUE$(NM_FRONT + 3))
	For loop_count = 1 To args_count Step 1
		NM_CMD$(NM_CMD_START + 3 + loop_count) = NM_QUEUE$(NM_FRONT + 3 + loop_count)
	Next

	If NM_FRONT + ARGS_UPPER_LIMIT >= NM_QUEUE_UPPER_LIMIT Then
		NM_FRONT = NM_QUEUE_START
    Else
        NM_FRONT = NM_FRONT + ARGS_UPPER_LIMIT
	EndIf
Fend