to be done：
Overall:
    1.need to merge all prgs together and change some Xqt to Call
    2.change ErrorHandling function to a global string array
    3.need to define an IO[] array based on real io

TSR0:
    Done, check if robot serial number can be used as controller serial number

TSR1:
    QueryIoMapping():
        1.why use variant here, why just define a new string as output and put everything in it?

TSR2:
    InputIo():
        1.IO_ARRAY is useless, change PARALLEL_IO_INPUT_START to zero and delete this
    OutputIo():
        1.need to check does Out() function change output status or just read io

TSR3:
    Done

TSR4:
    Done

TSR5:
    Done

TSR6:
    QueryIo():
        1. change to use InputIo() in TSR2 later after merge
    WaitInput():
        1. need to check if Time(2) can return a double value when return variable set to double

RobotTask：
    Main:
        1.confirm if sm equals to Waitpos
    MoveAction():
        3.donnt understand accuracy and @ symbol's meaning
        4.in move command, when pos_id=0, why use position dev to move but not directly use dest postion to move?
        5.donnt understand what Dev(RealPos,shift_position) + shift_position means, does it doubled shift_position's value or make it to be RealPos again?
        6.does waitPos equals to arrive 100? and can use waitPos as Motioncomplete?

Queue:
    Done, and need to be careful about function names        