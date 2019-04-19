////////////////////////////////////////////////////////////////////////////////////////////////////
//
//
//  Lady Green Forensic Component     : BYOS - SOUL STEALER
//
//  Signature                         : LGF/APPS/BYOS/SOUL-STEALER
//  LGF Version protocol              : 1.0.0.0
//  Component version                 : 0.1
//  release date                      : April 2019
//
//  Description : This component is the soul stealer of BYOS SYSTEM.
//                This script interacts with a SOUL_CATCHER BYOS Component
//                to steal the soul of the owner of that script
//
//
//  States description :
//      default:
//          current state when object is rezzed. Wait for a soul catcher.
//
//
//  Messages sent by SOUL-STEALER (Please refer to LGF msg directory)
//
//
//  Message managed by SOUL-STEALER (Please refer to LGF msg directory)
//
//
//  documentation : http://lgfsite.wordpress.com
//
//
//  copyright © Lady Green Forensic 2019
//
//  This script is free software: you can redistribute it and/or modify
//  it under the terms of the creative commons Attribution- ShareAlike 4.0
//  International licence. (http://creativecommons.org/licenses/by-sa/4.0/legalcode)
//
///////////////////////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////
// constants
////////////////////////////////////
string K_Version = "1.0.0.0"; // version of the component

integer CHANNEL_LGF_MASTER 		= - 7516; // listen channel for register processing by LGF master object
integer CHANNEL_LGF_SLAVE  		= - 7515; // listen channel for register processing by LGF master object

string  HEADER_LGF_PROT_SOUL_STEALER  = "LGF_MSG|LGF|BYOS|SOUL_STEALER|SOUL_STEALER|1.1.0.0|"; // LGF header message sent by object
string  LGF_PROT_MSG_BLIIP            = "BLIIP"; // LGF header message sent by object

////////////////////////////////////
// variables
////////////////////////////////////
List experiences=[];
integer experienceIndex=0;
integer gHandle = 0;

////////////////////////////////////
// init the process to steal a soul
////////////////////////////////////
stealSoul() {
  string origName = llGetObjectName();
  llStartAnimation("asslap");
  llPlaySound( "spankmoan", 1.0 );

  llSetObjectName(" ");
  llSay(PUBLIC_CHANNEL, llGetDisplayName(touchingKey) + " spanks " + llGetDisplayName(ownerKey) + "'s ass.");
  llSetObjectName(origName);

  // emit a bliip to be discovered by CATCHER
  bliip();
}

////////////////////////////////////
// Emit a bliip to be detected by catcher
////////////////////////////////////
bliip() {
  string msg = HEADER_LGF_PROT_SOUL_STEALER + LGF_PROT_MSG_BLIIP + "|" + (string)llGetKey();
  llSay(CHANNEL_LGF_MASTER, msg)
  llSetTimerEvent(10);
}

////////////////////////////////////
// load experiences
////////////////////////////////////
initExperience(){
  experiences=[];
  experienceIndex = 0;
  experiences+= "A whisper in the dark...";
  experiences+= "The wind in your mind. A call...'Come to me. Come to me...'";
  experiences+= "A presence....stealth.";
  experiences+= "Des griffes qui enserrent ton esprit. Une pression autour de celui-ci....";
  experiences+= "...De plus en fort. Des mots prononcés dans une langue incoonue.";
  experiences+= "...Et soudain le silence, le vide.";
  experiences+= "Une explosion dans ta tête, une aspiration, une force irrésistible qui te vide de toutes tes forces.";
  experiences+= "Et qui te laisse sans connaissance au sol.";

}

////////////////////////////////////
// display next experience
////////////////////////////////////
integer displayNextExperience() {
  integer returnCode = 1;

  if (experienceIndex >= llGetListLength(experiences)){
    returnCode = 0;
  } else {
    string experience = llList2String(experiences, experienceIndex);

    string origName = llGetObjectName();
    llSetObjectName(" ");
    llInstantMessage(llGetOwner(), experience);
    llSetObjectName(origName);

    experienceIndex = experienceIndex + 1
    if (experienceIndex >= llGetListLength(experiences)){
      returnCode = -1;
    }
  }

  return returnCode;
}

////////////////////////////////////
// log function
////////////////////////////////////
debug (string pLog) {
    if (debugMode == 1) {
        llSay(DEBUG_CHANNEL,llGetScriptName()  + ":" + pLog);
    }
}

////////////////////////////////////
// Default state
////////////////////////////////////
default
{
    state_entry()
    {
        initExperience();

        llRequestPermissions(llGetOwner(), PERMISSION_TRIGGER_ANIMATION);

        // set the timer to display the next im
        llSetTimerEvent(1.0);
    }

    timer() {
      // display experience until there are some experiences to be
      // displayed
      integer experienceStatus = displayNextExperience();
      if ( experienceStatus == 0){
        //experiences are ended. Now look for a soul catcher
        bliip();

      } else if ( experienceStatus == -1){
        // experiences are just finished
        handleListen = llListen(CHANNEL_LGF_SLAVE, "","","");
        bliip();
      } else {
        // Experiences are running
        llSetTimerEvent(6);
      }
    }

     listen(integer channel, string name, key id, string message) {

      if (channel == CHANNEL_LGF_MASTER) {
        list msg = decodeAndFilterLGFMessage(message);
      }
     }

}

steal{

}

empty{

}
