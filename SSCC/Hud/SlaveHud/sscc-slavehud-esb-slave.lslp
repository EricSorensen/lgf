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

string     gVersion = "0.10"; // version of the component

list     gOwners;        // list of owners
integer gDebug = 1;

integer gHandleMaster            = 0;
integer CHANNEL_LGF_MASTER         = - 7516; // listen channel for register processing by LGF master object
integer CHANNEL_LGF_SLAVE          = - 7515; // listen channel for register processing by LGF master object
string  HEADER_SLAVEHUD            = "LGF|SSCC|HUD|SLAVEHUD|1.1.0.0|"; // LGF header message sent by object

integer INDEX_REQ_ACTION           = 5;         // index in LGF message containing the REQUEST action
integer INDEX_REQ_INTERF           = 6;         // index in LGF message containing the supported interface of the sender
integer INDEX_REQ_INTERF_SEARCH    = 7; 
integer INDEX_REQ_ANSWER_ACK       = 7;         // index in LGF message containing the searched interface by the sender 

string  ACTION_BLIIP               	= "BLIIP";     // LGF Bliip message body
string  ACTION_REGISTER         	= "REGISTER";   // LGF Message body for LGF REGISTER
string  ACTION_REGISTER_ACK     	= "REGISTER_ANSWER";    // LGF Message body for LGF REGISTER ACKNOWLEDGE
string  ACTION_ASK_DATA         	= "ASK_DATA";    // LGF Message body : Ask for data
string  ACTION_ASK_DATA_ANSWER     	= "ASK_DATA_ANSWER";    // LGF Message body : Ask for data
string  ACTION_CHECK_STATUS			= "CHECK_STATUS";	// Heartbeat Management
string  ACK_SUCCESS                	= "SUCCESS";
string  ACK                         = "ACK";
string  ACK_ALREADY_CONNECTED       = "ALREADY_CONNECTED";

// LGF Interfaces handled
string  INTERFACE_SLAVE_HUD       = "SSCC-SLAVE-HUD";
string  INTERFACE_PLUGIN_SLAVE  = "SSCC-SLAVE-SUB";

// Internal message sent to SSCC scripts
// 10000 - 10049 : From Logic to GUI
integer I_MSG_SLAVE_CONNECTED           = 10000;
integer I_MSG_SLAVE_DISCONNECTED        = 10001;

// 10050 - 10099 : From GUI to Logic
integer I_MSG_SLAVE_CHECK_STATUS       	= 10050;



integer K_DELAY_POOLING_SLAVE = 30; // 30 sec before pooling a slave deice

key      gSlavePrimKey           = NULL_KEY;        // Key of Slave prim 
integer  gSlaveStatus			 = FALSE;

// log function
debug (string pLog) {
    if (gDebug == 1) {
        llOwnerSay(llGetScriptName()  + ":" + pLog);
    }
}

init_default () {

    gSlavePrimKey           = NULL_KEY;     
    
    // send a message to all components that the slave component is connected
    llMessageLinked (LINK_THIS, I_MSG_SLAVE_DISCONNECTED, "", NULL_KEY);

    // Prim listen the Slave channel for the owned/worn devices
    gHandleMaster = llListen(CHANNEL_LGF_MASTER, "","","");
    
    llSetTimerEvent(K_DELAY_POOLING_SLAVE);
            
}

exit_default() {
    
    llSetTimerEvent(0);
    llListenRemove (gHandleMaster);
}

init_connected() {
    
    gHandleMaster = llListen(CHANNEL_LGF_MASTER, "", gSlavePrimKey, ""); 
    
    // send a message to all components that the slave component is connected
    llMessageLinked (LINK_THIS, I_MSG_SLAVE_CONNECTED, "", gSlavePrimKey);
    
    // set the timer to pool the devices to connected
    //llSetTimerEvent(K_POOLING_DEVICES_DELAY);

}

exit_connected() {
    llListenRemove (gHandleMaster);    
}


integer handshakeHandler (list paramsMsg, string pAction, string pSuccess, key pSender) {
    
    string lReqInterfaceFrom =llList2String(paramsMsg,INDEX_REQ_INTERF);
    integer lReturn = FALSE;

    if (lReqInterfaceFrom == INTERFACE_PLUGIN_SLAVE) {
        // a SSCC SLAVE interface is required. we accept the request if owner of sender object 
        // is owner of collar
        list lDetails = llGetObjectDetails( pSender, ([OBJECT_OWNER]));
        key lKeyOwnerSender = llList2Key(lDetails,0);
    
        if (pAction ==  ACTION_BLIIP) {            
            debug ("Bliip message received");
            //     we check if the message is sent by a device of the owner
            if (lKeyOwnerSender == llGetOwner()) {
                // the slave device is owned by the avi
                // that wear the slave hud. we request a connexion
                llRegionSayTo (pSender, CHANNEL_LGF_SLAVE, HEADER_SLAVEHUD + ACTION_REGISTER + "|" + INTERFACE_SLAVE_HUD + "|" + INTERFACE_PLUGIN_SLAVE );
                                
            } 
        } else if (pAction == ACTION_REGISTER_ACK)    {
            debug ("Register ack message received");
            //     we check if the message is sent by a device of the owner
            if (lKeyOwnerSender == llGetOwner()) {
                // the slave device is owned by the avi
                // that wear the slave hud. we accept the connexion

                string lAckStatus  =llList2String(paramsMsg,INDEX_REQ_ANSWER_ACK);
                if (lAckStatus == ACK) {
                    gSlavePrimKey = pSender;
                    lReturn = TRUE;
                }
            } 
        
        }       
                        
    } 
    
    return lReturn;                   
}

checkStatus() {
	llRegionSayTo (gSlavePrimKey, CHANNEL_LGF_SLAVE, HEADER_SLAVEHUD + ACTION_CHECK_STATUS );
	gSlaveStatus = FALSE;
	llSetTimerEvent(K_DELAY_CHECK_STATUS);
}

default {
    state_entry() {
         init_default();  
    }
    
   state_exit() {
         exit_default();  
    }
    
    timer() {
         llRegionSay (CHANNEL_LGF_SLAVE, HEADER_SLAVEHUD + ACTION_REGISTER + "|" + INTERFACE_SLAVE_HUD + "|" + INTERFACE_PLUGIN_SLAVE );
    }

    
    on_rez (integer startParam) {
        llResetScript();
    } 
            
    
    //If owner changed...
    changed(integer iChange){
        if (iChange & (CHANGED_OWNER|CHANGED_LINK)) {
            llResetScript();
        }
    }    
    
    listen(integer channel, string name, key id, string message) {
       
        if (channel == CHANNEL_LGF_MASTER) {
            debug("Message received in master channel : " + message);
            // messages on the master channel are sent by worn devices

            // message received on the master channel
            // we parse the header of the message
            list paramsMsg = llParseString2List(message, ["|"], []);

            // we check if the header tells us that the message come from a hud LGF compatible
            if (llList2List(paramsMsg,4,4) == ["1.1.0.0"]) {
                
                string action = llList2String(paramsMsg, INDEX_REQ_ACTION);
                debug ("action = " + (string) action);
                if ((action == ACTION_BLIIP)  || (action == ACTION_REGISTER_ACK)){
                    // handle handshake connection
                    if (handshakeHandler(paramsMsg, action, ACK_SUCCESS,  id)) {
                        
                        // we stop to listen and we go to connected mode
                        state connected;
                    }
                    
                }
            }
        } 
    }
}

////////////////////////////////////////////////////////////
// This state is used when the HUD is connected to a      //
// slave identifier device                                //
////////////////////////////////////////////////////////////
state connected {
    
    state_entry() {
        init_connected();       
    }
    
    state_exit() {
        
    }
    
    timer() {
    	// Timer : used for heartbeat management.
    	if (gSlaveStatus == FALSE) {
    		llMessageLinked (LINK_THIS, I_MSG_SLAVE_DISCONNECTED, "", NULL_KEY);
    	} else {
    		llMessageLinked (LINK_THIS, I_MSG_SLAVE_CONNECTED, "", NULL_KEY);
    	}
    	llSetTimerEvent(0);
    }
        
    on_rez (integer startParam) {
        llResetScript();
    } 
            
    
    //If owner changed...
    changed(integer iChange){
        if (iChange & (CHANGED_OWNER|CHANGED_LINK)) {
            llResetScript();
        }
    } 
    
    listen(integer channel, string name, key id, string message) {
       
        if (channel == CHANNEL_LGF_MASTER) {
            debug("Message received in master channel : " + message);
            // messages on the master channel are sent by worn devices

            // message received on the master channel
            // we parse the header of the message
            list paramsMsg = llParseString2List(message, ["|"], []);

            // we check if the header tells us that the message come from a hud LGF compatible
            if (llList2List(paramsMsg,4,4) == ["1.1.0.0"]) {
                
                string action = llList2String(paramsMsg, INDEX_REQ_ACTION);
                
                if (action == ACTION_ASK_DATA_ANSWER){
                    
                }
            }
        } 
    } 
    
    link_message(integer sender_num, integer num, string msg, key id) {
    	
    	if ((num >= 10050) && (num < 10100)) {
    		
	    	if (num == I_MSG_SLAVE_CHECK_STATUS) {
	    		checkStatus();
	    		return;
	    	}
    	}
      
}
