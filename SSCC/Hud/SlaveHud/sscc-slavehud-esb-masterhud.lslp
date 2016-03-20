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

integer gHandleSlave            = 0;
integer gHandleMaster			= 0;
integer CHANNEL_LGF_MASTER 		= - 7516; // listen channel for register processing by LGF master object
integer CHANNEL_LGF_SLAVE  		= - 7515; // listen channel for register processing by LGF master object
string  HEADER_SLAVEHUD			= "LGF|SSCC|HUD|SLAVEHUD|1.1.0.0|"; // LGF header message sent by object
string  ACTION_BLIIP   			= "BLIIP";     // LGF Bliip message body

integer INDEX_REQ_ACTION   		= 5;         // index in LGF message containing the REQUEST action
integer INDEX_REQ_INTERF   		= 6;         // index in LGF message containing the supported interface of the sender
integer INDEX_REQ_INTERF_SEARCH = 7;         // index in LGF message containing the searched interface by the sender 
string  ACTION_REGISTER     	= "REGISTER";   // LGF Message body for LGF REGISTER
string  ACTION_REGISTER_ACK 	= "REGISTER_ANSWER";    // LGF Message body for LGF REGISTER ACKNOWLEDGE
string  ACK_SUCCESS				= "SUCCESS";
string  ACK_ALREADY_CONNECTED	= "ALREADY_CONNECTED";

// LGF Interfaces handled
string  INTERFACE_SLAVE_HUD   	= "SSCC-SLAVE-HUD";
string  INTERFACE_PLUGIN_SLAVE  = "SSCC-SLAVE-SUB";
string  INTERFACE_PLUGIN_MASTERHUD = "SSCC-MASTER-HUD";


integer K_POOLING_DEVICES_DELAY = 300; // 60 sec * 5 minutew

key  	gSlavePrimKey       	= NULL_KEY;    	// Key of Slave prim 
key 	gMasterHudKey			= NULL_KEY; 	// Key of the master hud prim
list	gWornDevicesKey			= [];			// list containing the key of all worn devices;	
    
// log function
debug (string pLog) {
    if (gDebug == 1) {
        llOwnerSay(llGetScriptName()  + ":" + pLog);
    }
}

init () {

	gSlavePrimKey       	= NULL_KEY;     
	gMasterHudKey			= NULL_KEY; 	
	gWornDevicesKey			= [];	
	
	// Prim listen the Slave channel for the master hud
	gHandleSlave = llListen(CHANNEL_LGF_SLAVE, "","","");

	// Prim listen the Slave channel for the owned/worn devices
	gHandleMaster = llListen(CHANNEL_LGF_MASTER, "","","");
        
	// set the timer to pool the devices to connected
	llSetTimerEvent(K_POOLING_DEVICES_DELAY);
	
}


handshakeHandler (list paramsMsg, string pAction, string pSuccess, key pSender) {
	// A request to register is received and slave object is not yet initialized
    // we check if the emitter Prim's owner is the owner of ther titler
    // we store the UUID of the master Prim
    integer lReturn = FALSE;
	
	string lReqInterfaceFrom =llList2String(paramsMsg,INDEX_REQ_INTERF);

	if (lReqInterfaceFrom == INTERFACE_PLUGIN_SLAVE) {
		// a SSCC SLAVE interface is required. we accept the request if owner of sender object 
		// is owner of collar
		list lDetails = llGetObjectDetails( pSender, ([OBJECT_OWNER]));
		key lKeyOwnerSender = llList2Key(lDetails,0);
	
		if (pAction == 	ACTION_BLIIP) {			
			
			// 	we check if the message is sent by a device of the owner
			if (lKeyOwnerSender == llGetOwner()) {
				// the slave device is owned by the avi
				// that wear the slave hud. we request a connexion
				llRegionSayTo (gSlavePrimKey, CHANNEL_LGF_SLAVE, HEADER_SLAVEHUD + ACTION_REGISTER + "|" + INTERFACE_SLAVE_HUD + "|" + INTERFACE_PLUGIN_SLAVE + "|" + pSuccess);
								
			} 
		} else if (pAction == ACTION_REGISTER_ACK)	{

			// 	we check if the message is sent by a device of the owner
			if (lKeyOwnerSender == llGetOwner()) {
				// the slave device is owned by the avi
				// that wear the slave hud. we accept the connexion
				gSlavePrimKey = pSender;
			} 
		
		} else if (lReqInterfaceFrom == INTERFACE_PLUGIN_MASTERHUD) {
			list lDetails = llGetObjectDetails( pSender, ([OBJECT_OWNER]));
			key lKeyOwnerSender = llList2Key(lDetails,0);
			string lReqInterfaceSearched = llList2String(paramsMsg,INDEX_REQ_INTERF_SEARCH);
			
			if (lReqInterfaceSearched == INTERFACE_SLAVE_HUD) {
				if (pAction == ACTION_REGISTER)	{
					
	        		integer indexOwnersList = llListFindList(gOwners, [lKeyOwnerSender]);
	        
					// 	we check if the owner of the devices that requires a Slave Hud
					// is an owner of the wearer
					if (indexOwnersList >= 0) {
						// sender item is owned by an owner of the slave/sub we accept
						// the connection
						
						// we test if the slave hud is already connected to a master
						// hud or not.
						if (gMasterHudPrimKey == NULL_KEY) {
							gMasterHudPrimKey = pSender;
							llRegionSayTo (gSlavePrimKey, CHANNEL_LGF_MASTER, HEADER_SLAVEHUD + ACTION_REGISTER_ACK +"|" + INTERFACE_PLUGIN_SLAVE + "|" + pSuccess);
						} else {
							gMasterHudPrimKey = pSender;
							llRegionSayTo (gSlavePrimKey, CHANNEL_LGF_MASTER, HEADER_SLAVEHUD + ACTION_REGISTER_ACK +"|" + INTERFACE_PLUGIN_SLAVE + "|" + ACK_ALREADY_CONNECTED);
						}
					}	
				}	
			}	
		} 		
                        
	} 
	
	return lReturn;
                    
}

default {
    state_entry() {
        
        
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
            debug("Message received in slave channel : " + message);
			// messages on the master channel are sent by worn devices

            // message received on the master channel
            // we parse the header of the message
            list paramsMsg = llParseString2List(message, ["|"], []);

            // we check if the header tells us that the message come from a hud LGF compatible
            if (llList2List(paramsMsg,4,4) == ["1.1.0.0"]) {
                
                string action = llList2String(paramsMsg, INDEX_REQ_ACTION);
                
                if ((action == ACTION_BLIIP) || (action == ACTION_REQUEST_ANSWER)){
                	// handle handshake connection
                	handshakeHandler(paramsMsg, action, ACK_SUCCESS,  id);
                	
                }
            }
        } else if (channel == CHANNEL_LGF_SLAVE) {
            debug("Message received in slave channel : " + message);
			// messages on the slave channel are sent by master hud 
            
            // message received on the slave channel
            // we parse the header of the message
            list paramsMsg = llParseString2List(message, ["|"], []);

            // we check if the header tells us that the message come from a  LGF compatible devices
            if (llList2List(paramsMsg,4,4) == ["1.1.0.0"]) {
                
                string action = llList2String(paramsMsg, INDEX_REQ_ACTION);
                
                if ((action == ACTION_BLIIP) || (action == ACTION_REQUEST)){
                	// handle handshake connection
                	handshakeHandler(paramsMsg, action, ACK_SUCCESS,  id);
                	
                }
        }
    }
}
