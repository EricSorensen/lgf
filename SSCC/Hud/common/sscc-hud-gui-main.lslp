////////////////////////////////////////////////////////////////////////////////////////////////////
//
//
//  Lady Green Forensic Component : SSCC COMMON HUD 
//
//  Signature : used in LGF/SSCC/HUD/SLAVEHUD LGF/SSCC/HUD/MASTERHUD
//  LGF Version protocol : 1.1.0.0
//  Component version : 0.1
//  release date : March 2016
//
//  Description : This script is a slave hud is used in a slave or a master gud. 
//					It manages the interaction with all the prim (linked or not)
//
//  State description : 
//      
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

integer gDebug = 1;




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
