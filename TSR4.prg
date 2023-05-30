'!TITLE "Communication sending task"

#include "Public.inc"
#include "ErrorHandling.prg"
#include "Queue.prg"

Function Main
    String temp_handling_string$ = ""
	String pop_string$ = ""
	Int32 string_size = 0
	Int32 queue_size = 0
	Int32 timeout_secs = 0
	Int32 comm_opened = 0
	Int32 send_bytes = 0
	Int32 test = 0
	String test2$ = ""
    TSR4_STATUS = 1
    SENDCONN_STATUS = 0

	Do While 1

	    CONNECTING:
		If RECVCONN_STATUS <> 0 Then
			Goto OPENING
		Else
			Goto START
		EndIf

		OPENING:
		SENDCONN_STATUS = 0

		OnErr Goto CONNECT_ERROR

		OpenNet #COM_SEND_PORT_NEW As Client
		comm_opened = 1

		WaitNet #COM_SEND_PORT_NEW 5
        If ChkNet(COM_SEND_PORT_NEW) < 0 Then
            Goto START
		EndIf

		SENDCONN_STATUS = 1

        START:
        If TSR4_STATUS <> TSR4_REQUEST_STATUS Then
            TSR4_STATUS = TSR4_REQUEST_STATUS
        EndIf
        If TSR4_STATUS= 0 Then
            Wait 0.1
			If CHECK_TASK_STATE(TSR0) Then
				TSR4_REQUEST_STATUS = 1
			EndIf
            Goto START
        EndIf

        SEND:
        If RECVCONN_STATUS = 0 Or ChkNet(COM_SEND_PORT_NEW) < 0 Then    'todo: same
            Goto CONNECT_ERROR
        EndIf

        queue_size = CMD_SEND_BACK - CMD_SEND_FRONT

        If queue_size <> 0 Then ' queue is not empty

			pop_string$ = PopCmdSendQueue()
			If temp_handling_string$ = "" Then
            	temp_handling_string$ = pop_string$ + "#"
			Else
	            temp_handling_string$ = temp_handling_string$ + Chr$(13) + pop_string$ + "#"		
			EndIf
        EndIf
		
        If IO_UPDATE_REQUEST = 1 Then
			If temp_handling_string$ = "" Then
            	temp_handling_string$ = IO_UPDATE_CMD$ + "#"
			Else
	            temp_handling_string$ = temp_handling_string$ + Chr$(13) + IO_UPDATE_CMD$ + "#"		
			EndIf
			IO_UPDATE_REQUEST = 0
        EndIf

        If NM_UPDATE_REQUEST = 1 Then
			If temp_handling_string$ = "" Then
            	temp_handling_string$ = NM_UPDATE_CMD$ + "#"
			Else
	            temp_handling_string$ = temp_handling_string$ + Chr$(13) + NM_UPDATE_CMD$ + "#"		
			EndIf
			NM_UPDATE_REQUEST = 0
        EndIf

        string_size = Len(temp_handling_string$)

        If (string_size > 0 And (string_size > 150 Or queue_size = 1 Or queue_size = 0)) Then
			Write #COM_SEND_PORT_NEW temp_handling_string$
            temp_handling_string$ = ""

        EndIf

        queue_size = CMD_SEND_BACK - CMD_SEND_FRONT
        If (queue_size = 0) Then
            Wait 0.005
            Goto START
        Else
            Goto SEND
        EndIf

        CONNECT_ERROR:
		RECVCONN_STATUS = 0
		SENDCONN_STATUS = 0
		If comm_opened Then
			CloseNet #COM_SEND_PORT_NEW             
			comm_opened = 0
		EndIf
        Wait 1
        Goto CONNECTING

    Loop
Fend