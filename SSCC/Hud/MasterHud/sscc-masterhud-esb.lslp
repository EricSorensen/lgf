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
//					master hud and all worn devices by the sub/slave
//
//  State description : 
//      
//                      
//
//  LGF interfaces implemented by this script (Please refer to LGF interfaces directory):
//			- SSCC-SLAVE-HUD
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

string 	gVersion = "0.10"; // version of the component

list 	gOwners;        // list of owners
integer gDebug = 1;

integer gHandle            		= 0;
integer CHANNEL_LGF_MASTER 		= - 7516; // listen channel for register processing by LGF master object
integer CHANNEL_LGF_SLAVE  		= - 7515; // listen channel for register processing by LGF master object
string  HEADER_SLAVEHUD			= "LGF|SSCC|HUD|SLAVEHUD|1.1.0.0|"; // LGF header message sent by object
string  ACTION_BLIIP   			= "BLIIP";     // LGF Bliip message body
string  INTERFACE_SLAVE_HUD   	= "SSCC-SLAVE-HUD";
string  INTERFACE_PLUGIN_SLAVE  = "SSCC-SLAVE-SUB";
integer INDEX_REQ_ACTION   		= 5;         // index in LGF message containing the REQUEST action
integer INDEX_REQ_INTERF   		= 6;         // index in LGF message containing the REQUEST action
integer INDEX_MASTER_UID   		= 7;         // index in LGF message containing the Master prim UUID
string  ACTION_REGISTER     	= "REGISTER_REQUEST";   // LGF Message body for LGF REGISTER
string  ACTION_REGISTER_ACK 	= "REGISTER_ANSWER";    // LGF Message body for LGF REGISTER ACKNOWLEDGE

key  gSlavePrimKey       = NULL_KEY;    // Key of the HUD UUID associated with the titler

    
// log function
debug (string pLog) {
    if (gDebug == 1) {
        llOwnerSay(llGetScriptName()  + ":" + pLog);
    }
}


integer actionRegisterHandler (list paramsMsg, string pSuccess, key pSender) {
	// A request to register is received and slave object is not yet initialized
    // we check if the emitter Prim's owner is the owner of ther titler
    // we store the UUID of the master Prim
    integer lReturn = FALSE;
	
	string lReqInterface =llList2String(paramsMsg,INDEX_REQ_INTERF);

	if (lReqInterface == INTERFACE_PLUGIN_SLAVE){
		// a SSCC SLAVE interface is required. we accept the request if owner of sender object 
		// is owner of collar
		gSlavePrimKey = pSender;
		list lDetails = llGetObjectDetails( gSlavePrimKey, ([OBJECT_OWNER]));
		key lKeyOwnerSender = llList2Key(lDetails,0);
						
		if (llListFindList(gOwners, [lKeyOwnerSender])> 0) {
			// owner of SSCC_MASTER is in list of owner of collar
			// Handshake is accepted
			llRegionSayTo (masterPrimKey, CHANNEL_LGF_MASTER, HEADER_SLAVE_TITLER + ACTION_REGISTER_ACK +"|" + pSuccess);
							
			// we change the state to connected
			lReturn = TRUE;
		} else {
			// Master hud owner is not declarer as owner of collar
			// we reject the request
			llRegionSayTo (masterPrimKey, CHANNEL_LGF_MASTER, HEADER_SLAVE_TITLER + ACTION_REGISTER_ACK +"|" + NACK);
		}
						
                        
	} else {
		// a non SSCC SLAVE interface is required. we rejetct the request
        llRegionSayTo (masterPrimKey, CHANNEL_LGF_MASTER, HEADER_SLAVE_TITLER + ACTION_REGISTER_ACK +"|" + NACK);
	}
	
	return lReturn;
                    
}

default {
    state_entry() {
        
        // Prim listen the Slave channel
        gHandle = llListen(CHANNEL_LGF_SLAVE, "","","");
        
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
       
        if (channel == CHANNEL_LGF_SLAVE) {
            debug("Message received in slave channel : " + message);

            // message received on the slave channel
            // we parse the header of the message
            list paramsMsg = llParseString2List(message, ["|"], []);

            // we check if the header tells us that the message come from a hud LGF compatible
            if (llList2List(paramsMsg,4,4) == ["1.1.0.0"]) {
                
                string action = llList2String(paramsMsg, INDEX_REQ_ACTION);
                
                if (action == ACTION_BLIIP){
                	// effectuer une demande de connection immediate si l'interface est correcte
                	integer lReturn = actionRegisterHandler(paramsMsg, (string)llGetKey());
                	
                	if (lReturn == TRUE) {
                		state connected;
                	} 
                }
                
            
            }
        }
    }
}

state connected {
    state_entry (){
        // we start listening on the slave channel if required
        gHandle = llListen(CHANNEL_LGF_SLAVE, "","",""); 
    }
    
    on_rez (integer startParam) {
        llResetScript();
    } 
    
    listen(integer channel, string name, key id, string message) {
       
        if (channel == CHANNEL_LGF_SLAVE) {
            debug ("Message received in slave channel : " + message);

            // message received on the slave channel
            // we parse the header of the message
            list paramsMsg = llParseString2List(message, ["|"], []);

            // we check if the header tells us that the message come from a hud LGF compatible
            if (llList2List(paramsMsg,4,4) == ["1.1.0.0"]) {
                
                string action = llList2String(paramsMsg, INDEX_REQ_ACTION);
                
                if (action == ACTION_REGISTER){
                    // A request to register is received and slave object is not yet initialized
                    // we check if the emitter Prim's owner is the owner of ther titler
                    // we store the UUID of the master Prim
                    actionRegisterHandler(paramsMsg, ALREADY_CONNECTED);
                }
                
            
            }
        }
    }
}