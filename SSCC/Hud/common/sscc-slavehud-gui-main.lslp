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

integer gDebug = 0;




// log function
debug (string pLog) {
    if (gDebug == 1) {
        llOwnerSay(llGetScriptName()  + ":" + pLog);
    }
}

default {
    state_entry() {
        
    }
    
    touch_end (integer pNumDetected) {
        integer lPrimIndex =  llDetectedLinkNumber(0);
    	integer lFace = llDetectedTouchFace(0);
    	list lParams = llGetLinkPrimitiveParams(lPrimIndex, [PRIM_DESC]);
    	
    	integer lEvent = llList2Integer (lParams, 0);
    	
    	if (lEvent != 0) {
    		debug ("Event fired: " + (string) lEvent + " - face: " + (string) lFace);
    		   
    		string lMessage = (string) lEvent + "|" + (string) lFace;
    		// send a message to all components that the slave component is connected
    		llMessageLinked (LINK_THIS,0 , lMessage, NULL_KEY);
    		
    	}
    	
    	
    
    }
    
    
}
