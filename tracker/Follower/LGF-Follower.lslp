////////////////////////////////////////////////////////////////////////////////////////////////////
//
//
//  Lady Green Forensic Component : Common components 
//
//  Signature : LGF/COMMON/FOLLOWER/MAIN
//  LGF Version protocol : 1.1.0.0
//  Component version : 0.1
//  release date : Septmber 2016
//
//  Description : This component is a common components : a follower
//                  
//
//  State description : 
//      
//                      
//
//  LGF interfaces implemented by this script (Please refer to LGF interfaces directory):
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

string      gVersion        = "0.10"; // version of the component
integer     gDebug          = 1;

integer CHANNEL_DIALOG = -6000;
integer MSG_FOLLOWER = 7555;

string PARAM_FOLLOWER_ON             = "ON";
string PARAM_FOLLOWER_OFF             = "OFF";
string PARAM_FOLLOWER_PARAM_LENGTH     = "LENGTH=";

key     gKeyToucher = NULL_KEY;
integer tid = 0;
integer announced = FALSE;
integer followerState = 0;
key targetKey = NULL_KEY;

float DELAY = 0.5;   // Seconds between blinks; lower for more lag
float RANGE = 3.0;   // Meters away that we stop walking towards
float TAU = 1.0;     // Make smaller for more rushed following
 
// Avatar Follower script, by Dale Innis
// Do with this what you will, no rights reserved
// See https://wiki.secondlife.com/wiki/AvatarFollower for instructions and notes
 
float LIMIT = 60.0;   // Approximate limit (lower bound) of llMoveToTarget


// log function
debug (string pLog) {
    if (gDebug == 1) {
        llOwnerSay(llGetScriptName()  + ":" + pLog);
    }
}

init_default() {
}


stopFollowing() {
  llTargetRemove(tid);  
  llStopMoveToTarget();
  llSetTimerEvent(0.0);
  debug ("No longer following " +  llKey2Name(gKeyToucher));
  followerState = 0;
}

startFollowingKey(key id) {
  debug ("Start to follow " +  llKey2Name(gKeyToucher));
  targetKey = id;
  followerState = 1;
  keepFollowing();
  llSetTimerEvent(DELAY);
}
 
keepFollowing() {
  llTargetRemove(tid);  
  llStopMoveToTarget();
  list answer = llGetObjectDetails(gKeyToucher,[OBJECT_POS]);
  if (llGetListLength(answer)==0) {
    if (!announced) debug(llKey2Name(targetKey)+" seems to be out of range.  Waiting for return...");
    announced = TRUE;
  } else {
    announced = FALSE;
    vector targetPos = llList2Vector(answer,0);
    float dist = llVecDist(targetPos,llGetPos());
    if (dist>RANGE) {
      tid = llTarget(targetPos,RANGE);
      if (dist>LIMIT) {
          targetPos = llGetPos() + LIMIT * llVecNorm( targetPos - llGetPos() ) ; 
      }
      llMoveToTarget(targetPos,TAU);
    }
  }
}



default {
    state_entry() {
         init_default();  
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
    
    link_message(integer nSenderNum, integer nNum, string szMsg, key keyID)  {
        if (nNum == MSG_FOLLOWER) {
            if (szMsg == PARAM_FOLLOWER_ON) {
                gKeyToucher = keyID;
                startFollowingKey(gKeyToucher);
                
            } else if (szMsg == PARAM_FOLLOWER_OFF){
                stopFollowing();
            }
        }
    }  
    
    
    timer() {
        keepFollowing();
    }
 
    at_target(integer tnum,vector tpos,vector ourpos) {
        llTargetRemove(tnum);
        llStopMoveToTarget(); 
    }    
}
