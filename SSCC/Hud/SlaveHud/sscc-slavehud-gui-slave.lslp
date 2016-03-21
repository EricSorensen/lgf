////////////////////////////////////////////////////////////////////////////////////////////////////
//
//
//  Lady Green Forensic Component : SSCC SLAVE HUD 
//
//  Signature : LGF/SSCC/HUD/SLAVEHUD
//  LGF Version protocol : 1.1.0.0
//  Component version : 0.1
//  release date : March 2016
//
//  Description : This component is a slave hud. It allows and interaction with a
//                    master hud and all worn devices by the sub/slave
//
//  State description : 
//      
//                      
//
//  LGF interfaces implemented by this script (Please refer to LGF interfaces directory):
//            - SSCC-SLAVE-HUD
//
//  Messages sent by SLAVEHUD except those required by implemented interfaces (Please refer to LGF msg directory)
//
//  Messages handled by SLAVEHUD except those required by implemented interfaces (Please refer to LGF msg directory)
//
//  documentation : http://lgfsite.wordpress.com
//
//
//  copyright © Lady Green Forensic 2016
//
//  This script is free software: you can redistribute it and/or modify     
//  it under the terms of the creative commons Attribution- ShareAlike 4.0 
//  International licence. (http://creativecommons.org/licenses/by-sa/4.0/legalcode)
//
///////////////////////////////////////////////////////////////////////////////////////////////////

// GUI messages
// Range 0-100 : Slave
integer GUI_MSG_SLAVE_HEARTBEAT         = 1;

// 10000 - 10049 : From Logic to GUI
integer I_MSG_SLAVE_CONNECTED            = 10000;
integer I_MSG_SLAVE_DISCONNECTED        = 10001;

// 10049 - 10099 : From GUI to Logic
integer I_MSG_SLAVE_CHECK_STATUS           = 10050;

integer gDebug = 1;




// log function
debug (string pLog) {
    if (gDebug == 1) {
        llOwnerSay(llGetScriptName()  + ":" + pLog);
    }
}

connectSlave (key id) {
    
    llSetColor(<0.0, 1.0, 0.0>, ALL_SIDES);
}

disconnectSlave(key id) {
    llSetColor(<1.0, 0.0, 0.0>, ALL_SIDES);
}

sendHeartbeat() {
    llMessageLinked (LINK_THIS,I_MSG_SLAVE_CHECK_STATUS , "", NULL_KEY);
}

default {
    state_entry() {
        
    }
    
    link_message(integer sender_num, integer num, string msg, key id) {
        
        if (msg != "") {
            //////////////////////////////////////
            // Message from GUI                 //
            //////////////////////////////////////
            list lParamsMsg         = llParseString2List(msg, ["|"], []);
            integer lGuiMsgNumber    = llList2Integer(lParamsMsg,0);
            //integer lGuiMsgFace     = llList2Integer(lParamsMsg,1);
            debug ("Message from GUI : " + (string)lGuiMsgNumber  );
            
            if ((lGuiMsgNumber>0) && (lGuiMsgNumber<100)) {
                
                if (lGuiMsgNumber == GUI_MSG_SLAVE_HEARTBEAT) {
                    sendHeartbeat();
                    return; 
                }
            }            
        } else {
            //////////////////////////////////////
            // Message from Business Logic      //
            //////////////////////////////////////
            
            
            if (num == I_MSG_SLAVE_CONNECTED) {
                connectSlave(id);
                return;
            }
            
            if (num == I_MSG_SLAVE_DISCONNECTED) {
                disconnectSlave(id);
                return;
            }
        }
        
    }
}
