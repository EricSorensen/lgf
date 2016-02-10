////////////////////////////////////////////////////////////////////////////////////////////////////
//
//
//  Lady Green Forensic Component     : MEDIA RING
//
//  Signature                         : LGF/SSCC/MEDIA/MEDIA_RING
//  LGF Version protocol              : 1.0.0.0
//  Component version                 : 0.10
//  release date                      : January 2016
//
//  Description : This component play a sound in a infinite loop
//
//  State description : Defaut is used when the prim does not play music
//						play is the state when the prim plays the sound
//
//  Messages sent by MEDIA RING : None
//
//  Message managed by MEDIA RING : None
//
//
//  documentation : http://lgfsite.wordpress.com
///////////////////////////////////////////////////////////////////////////////////////////////////


key gWearer;
integer gDebug = 0;
string gSoundToPlay = "MUSIC_SerreMoi";

init_default() {
	gWearer = llGetOwner();
	
	llStopSound();
	debug("Stopping the music...");
	
}

init_play() {
	llLoopSound(gSoundToPlay, 0.5);
	debug("Now playing the music...");
}

// log function
debug (string pLog) {
    if (gDebug == 1) {
        llOwnerSay(llGetScriptName()  + ":" + pLog);
    }
}

default {
    state_entry() {
        init_default();
    }
    
    touch_start(integer av) {
    	if (llDetectedKey(0) == gWearer) {
    		state play;
    	} 
    }
}

state play {
	state_entry() {
        init_play();
    }
    
    on_rez(integer param){
    	state default;
    }
    
     //If owner changed...
    changed(integer iChange){
        if (iChange & (CHANGED_OWNER|CHANGED_LINK)) {
        	state default;
        }
    }
    
    touch_start(integer av) {
		if (llDetectedKey(0) == gWearer) {
    		state default;
    	}
    }
}
