////////////////////////////////////////////////////////////////////////////////////////////////////
//
//
//  Lady Green Forensic Component 	: TITLER
//
//  Signature 						: LGF/TBOX/DISP/TITL
//  LGF Version protocol 			: 1.0.0.0
//  Component version 				: 0.1
//  release date 					: October 2015
//
//  Description : This component is a titler which can interact with one LGF component
//                using the LGF protocol active objects integration 
//                During LGF handshake, the titler registers the LGF master component 
//                and wait for a message from it to display or to clean.
//
//  State description : Defaut is the state when the titler is not initialized
//                      i.e not linked to his hud
//      
//                      Titler is set to active state once registered to one LGF master object
//
//  Messages sent by Titler (Please refer to LGF msg directory)
//              - BLIIP
//              - REGISTER_ANSWER
//
//  Message managed by Titler (Please refer to LGF msg directory)
//              - REGISTER_REQUEST
//              - SET_TITLER
//              = UNSET_TITLER
//
//  documentation : http://lgfsite.wordpress.com
///////////////////////////////////////////////////////////////////////////////////////////////////


integer lh                 = 0;
integer CHANNEL_LGF_MASTER = - 7516; // listen channel for register processing by LGF master object
integer CHANNEL_LGF_SLAVE  = - 7515; // listen channel for register processing by LGF master object
string  HEADER_SLAVE_TITLER= "LGF|TBOX|DISP|TITL|1.0.0.0|"; // LGF header message sent by Titler
string  MSG_BODY_BLIIP   = "BLIIP";     // LGF Bliip message body
integer INDEX_MASTER_UID   = 6;         // index in LGF message containing the Master prim UUID
integer INDEX_REQ_ACTION   = 5;         // index in LGF message containing the REQUEST action
integer INDEX_REQ_LABEL    = 7;         // index in LGF message containing the label to display or empty string to clean
string  ACTION_REGISTER     = "REGISTER_REQUEST";   // LGF Message body for LGF REGISTER
string  ACTION_REGISTER_ACK = "REGISTER_ANSWER";    // LGF Message body for LGF REGISTER ACKNOWLEDGE
string  ACTION_SET_TITLE    = "SET_TITLE";          // LGF Message body for set a titler
string  ACTION_UNSET_TITLE  = "UNSET_TITLE" ;       // LGF Message body for unset a titler

string  masterPrimKey       = "";    // Key of the HUD UUID associated with the titler

    
// logger
log (string msg) {
	//llOwnerSay (string msg);	
}
 
sendBlipMsg() {

    // Blip message has to be broadcaster on master Channel
    // since the titler is designed to interact only with attached object
    // he can send message using llWhisper
    llWhisper(CHANNEL_LGF_MASTER, HEADER_SLAVE_TITLER +MSG_BODY_BLIIP + "|" + (string) llGetKey () );
    log("Titler broadcast bliip");
} 

default {
    state_entry() {
        
        // Prim listen the Slave channel
        lh = llListen(CHANNEL_LGF_SLAVE, "","","");
        
        // Send blip message to tell to master that object is ready to receive message
        sendBlipMsg();
    }
    
    on_rez (integer startParam) {
        llResetScript();
    } 
    
    listen(integer channel, string name, key id, string message) {
        // in this state the titler wait for message from master hud
        log("Titler receive message :" + message);
       
        if (channel == CHANNEL_LGF_SLAVE) {
            log("Titler receive message in slave channel : " + message);

            // message received on the slave channel
            // we parse the header of the message
            list paramsMsg = llParseString2List(message, ["|"], []);
            // we check if the header tells us that the message come from a hud LGF compatible
            if (llList2List(paramsMsg,0,4) == ["LGF","TRCK","FOLW", "HUD", "1.0.0.0"]) {
                log("Titler receive message from hud follower");
                
                string action = llList2String(paramsMsg, INDEX_REQ_ACTION);
                log("Titler received message action " + action);
                
                if (action == ACTION_REGISTER){
                    // A request to register is received and slave object is not yet initialized
                    // we check if the emitter Prim's owner is the owner of ther titler
                    // we store the UUID of the master Prim
                    log("Titler receive message to register");
                    masterPrimKey = llList2String(paramsMsg, INDEX_MASTER_UID);

                    if (llGetOwnerKey(masterPrimKey)  == llGetOwner()) {    
                        log("Titler receive message from worn hud");
                        // owner of titler and owner of HUD are identical
                        // we stop listening
                        //llListenRemove(lh);
                        
                        //we send the ACK message to masterPrim
                        log("Titler send register to hud");
                        llRegionSayTo (masterPrimKey, CHANNEL_LGF_MASTER, HEADER_SLAVE_TITLER + ACTION_REGISTER_ACK +"|" + (string)llGetKey());
                        
                        // we change the state to active
                        state active;
                    }
                    
                }
                
            
            }
        }
    }
}

state active {
    state_entry (){
        // we start listening on the slave channel if required
        lh = llListen(CHANNEL_LGF_SLAVE, "","",""); 
    }
    
    on_rez (integer startParam) {
        llResetScript();
    } 
    
    listen(integer channel, string name, key id, string message) {
        // in this state the titler wait for message from master hud
        // in this state the titler wait for message from master hud
        log("Titler receive message on active state:" + message);
                
        if (channel == CHANNEL_LGF_SLAVE) {
            log("Titler receive message on active state on slave channel.");
            // message received on the slave channel
            // we parse the header of the message
            list paramsMsg = llParseString2List(message, ["|"], []);
            
            // we check if the header tells us that the message come from a hud LGF compatible
            if ( llList2List(paramsMsg, 0,4) == ["LGF","TRCK","FOLW", "HUD", "1.0.0.0"]) {
                
                string action = llList2String(paramsMsg, INDEX_REQ_ACTION);
                
                log("Titler receive message on active state. Action is:" + action);
                // A request to register is received and slave object is not yet initialized
                // we check if the emitter Prim's owner is the owner of ther titler
                string requestor = llList2String(paramsMsg, INDEX_MASTER_UID);

                if (llGetOwnerKey(requestor)  == llGetOwner()) {    
                
                    // owner of titler and owner of HUD are identical
                    if (action == ACTION_SET_TITLE){
                        // we want to set the titler
                        string title = llList2String(paramsMsg, INDEX_REQ_LABEL);
                        
                        //we set the title
                        vector COLOR_GREEN = <0.0, 1.0, 0.0>;
                        float  OPAQUE      = 1.0;

                        llSetText(title, COLOR_GREEN, OPAQUE );
                            
                    } else if (action == ACTION_UNSET_TITLE) {
                        llSetText("", ZERO_VECTOR, 0);
                    } else if (action == ACTION_REGISTER){
                        // Titler is attached to a HUD. He will not answer to this request
                        // except if the Requestor is the HUD already registered
                         masterPrimKey = requestor;
                        //we send the ACK message to masterPrim
                        log("Titler send register to hud");
                        llRegionSayTo (masterPrimKey, CHANNEL_LGF_MASTER, HEADER_SLAVE_TITLER + ACTION_REGISTER_ACK +"|" + (string)llGetKey());
                    }
                    
                }
            }
        }    
    }
}