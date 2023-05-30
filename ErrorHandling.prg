'!TITLE "Error Handling"

Function ErrorHandling( error_messages() As String ) As String                        'todo: check use ()or[], need compile

	error_messages(0,0) = "0,Success"
	
	error_messages(1,1) = "00101,Program Not Running due to E-Stop Engaged"
	error_messages(1,2) = "00102,Program Not Running due to Not Automation Mode"
	'error_messages(1,3) = "00103,Program Stopped due to FO3 Off"
	error_messages(1,4) = "00104,Program Stopped due to Unknown System Error"
	error_messages(1,5) = "00105,Program Not Running"
	error_messages(1,6) = "00106,Error State Not Cleared"
	error_messages(1,7) = "00107,Motion is still Ongoing"
	error_messages(1,8) = "00108,Motion Task is still Initializing"

	error_messages(2,1) = "00201,Invalid Param"
	error_messages(2,2) = "00202,Args Count Invalid Error"
	error_messages(2,3) = "00203,Input IO Index Error"
	error_messages(2,4) = "00204,Output IO Index Error"
	error_messages(2,5) = "00205,Unknown Command"
	error_messages(2,6) = "00206,Args Count Exceed Error"
	error_messages(2,7) = "00207,Invalid Command"

	error_messages(3,1) = "00301,Set Output Error"
	error_messages(3,2) = "00302,Wait Input Time Out"
	error_messages(3,3) = "00303,Check Input Failed"
Fend