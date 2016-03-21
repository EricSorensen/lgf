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
//  Description : This component is used in a slave hud or a master hud. 
//					It's a events scheduler. All hud scripts use it to handle
//					their timer
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

list events = [];
 
// PARAMS:
//    id     - the unique, positive id you associate with your event, use of global variables is recommended here.
//    time - the time at which you want the event to try and execute.
//    data - a piece of data you want passed to your handler when the event executes.
scheduleEvent(integer id, integer time, string data) {
    events = llListSort((events = []) + events + [time, id, data], 3, TRUE);
    setTimer(FALSE);
}

liftEvent (integer pId) {
	integer lIndex = llListFindList(events, [pId]);
	
	if (lIndex > 0) {
		// on retire l'évenement de la liste
		events = llDeleteSubList(events, lIndex-1, lIndex+1); 
		// on recalcule le timer
		setTimer(FALSE);
	}
}
 
// This function sets the timer correctly for the next scheduled event, or de-activates the timer 
// if there are no event remaining
integer setTimer(integer executing) {
    if ((events != []) > 0) { // Are there any list items?
        integer time = llList2Integer(events, 0);
 
        float t = (float)(time - llGetUnixTime());
        if (t <= 0.0) {
            if (executing) return TRUE;
            else t = 0.01;
        }
        llSetTimerEvent(t);
    } else { llSetTimerEvent(0.0); }
    return FALSE;
}
 
// Place your event handling code in here
handleEvent(integer pId, string pData) {
	//if an event is fired, we send the message
	llMessageLinked (LINK_THIS, pId+200, pData, NULL_KEY);
}
 
default {
    state_entry() {
    }
    
    link_message(integer pSenderNum, integer pNum, string pMsg, key pId) {
    	
    	if ((pNum>=9000) && (pNum <=9199)) {
    		// this is a timer event.
    		integer lTime = (integer)pMsg;
    		scheduleEvent(pNum, lTime, "");
    	} else if ((pNum>=9400) && (pNum <=9599)) {
    		//this is a message to lift an event
    		liftEvent(pNum);
    	}
    }
 
    timer() {
        // Clear timer or it might fire again before we're done
        llSetTimerEvent(0.0);
 
        do {
            // Fire the event
            handleEvent(llList2Integer(events, 1), llList2String(events, 2));
 
            // Get rid of the first item as we've executed it
            integer l = events != [];
            if (l > 0) {
                if (l > 3)
                    events = llList2List((events = []) + events, 3, -1);
                else events = [];
            }
 
            // Prepare the timer for the next event
        } while (setTimer(TRUE));
    }
}
