'!TITLE "Communication receiving task"

'#include "Public.inc"
#include "ErrorHandling.prg"
#include "Queue.prg"

Function Main
    String recv_msg_str$
    Int32 recv_msg_size
    String completed_command_string$
    Int32 string_limited_size                                   'todo: why 198? can change in Epson?
    string_limited_size = 198
    Int32 handled_size
    Int32 handling_size
	Int32 timeout_secs

    TSR3_STATUS = 1
    RECVCONN_STATUS = 0

    OpenNet #COM_RECV_PORT_NEW As Client
	WaitNet #COM_RECV_PORT_NEW 

	Do While 1                                       
	    'INIT:
	    RECVCONN_STATUS = 0
		On Error Goto SERVER_INIT
        OpenNet #COM_RECV_PORT_NEW As Server

        WAIT_CONNECTED:
        RECVCONN_STATUS = 0
        WaitNet #COM_RECV_PORT_NEW 5                            'todo: need check if WaitNet is a blocking function        
        If ChkNet(COM_RECV_PORT_NEW) < 0 Then
            Goto START
        EndIf

		RECVCONN_STATUS = 1

        START:
        If TSR3_STATUS <> TSR3_REQUEST_STATUS Then
            TSR3_STATUS = TSR3_REQUEST_STATUS
        EndIf
        If TSR3_STATUS = 0 Then
            Wait 0.1
			If CHECK_TASK_STATE(TSR0) Then
				TSR3_REQUEST_STATUS = 1
			EndIf
            Goto START
        EndIf
		
        If RECVCONN_STATUS = 0 Then
            Goto WAIT_CONNECTED
        EndIf

        recv_msg_size = ChkNet(COM_RECV_PORT_NEW)
        If recv_msg_size > 0 Then
            handled_size = 0
            handling_size = 0
            GETSTR_START:
            If recv_msg_size - handled_size > string_limited_size Then
                handling_size = string_limited_size
            Else
                handling_size = recv_msg_size - handled_size
            EndIf
            Read #COM_RECV_PORT_NEW recv_msg_str$ handling_size
            handled_size = handled_size + handling_size
            If recv_msg_str$ = "" Then
                Goto SPLIT_END
            EndIf

            Int32 temp_handling_msg_size
            String temp_handling_string$
            Int32 pos_end_index
            String incomplete_command_string$
			Int32 temp_for_right

            completed_command_string$ = ""
            temp_handling_string$ = recv_msg_str$
            
            SPLIT_START:
            temp_handling_msg_size = Len(temp_handling_string$)
            If (temp_handling_msg_size > 0) Then
                pos_end_index = InStr(temp_handling_string$,"#")
                If (pos_end_index > 0 And pos_end_index <= temp_handling_msg_size) Then
                    completed_command_string$ = incomplete_command_string$ + Left$(temp_handling_string$,pos_end_index - 1)
                    Call PushCmdToRecvQueue(completed_command_string$)
                    completed_command_string$ = ""
					temp_for_right = temp_handling_msg_size - pos_end_index
                    temp_handling_string$ = Right$(temp_handling_string$,temp_for_right)
                    incomplete_command_string$ = ""
                    Goto SPLIT_START
                Else
                    incomplete_command_string$ = incomplete_command_string$ + temp_handling_string$
                    Goto SPLIT_END
                EndIf
            EndIf
            SPLIT_END:
            If handled_size < recv_msg_size Then
				recv_msg_str$ = ""
				Goto GETSTR_START
            EndIf
		Else
			If recv_msg_size < 0 Then              
                Goto WAIT_CONNECTED
			EndIf
        EndIf

        Goto START

        SERVER_INIT:
        Call CloseSocket()
        Wait 0.1
        Goto INIT

    Loop
Fend

'---------- Sub ----------
Function CloseSocket()
	If ChkNet(COM_RECV_PORT_NEW) < 0 Then                    
        CloseNet #COM_RECV_PORT_NEW
	RECVCONN_STATUS = 0
Fend
