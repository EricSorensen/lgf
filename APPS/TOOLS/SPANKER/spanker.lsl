////////////////////////////////////////////////////////////////////////////////////////////////////
//
//
//  Lady Green Forensic Component     : SPANKER
//
//  Signature                         : LGF/APPS/TOOLS/SPANKER
//  LGF Version protocol              : 1.0.0.0
//  Component version                 : 0.1
//  release date                      : April 2019
//
//  Description : This component is a personnalized spanker
//
//
//  States description :
//      Default:
//          current state when object is rezzed.
//
//
//  Messages sent by SPANKER (Please refer to LGF msg directory)
//
//  Message managed by SPANKER (Please refer to LGF msg directory)
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
string K_Version = "0.1.0.0"; // version of the component
integer K_CHANNEL_SPANKER=19914637;
string K_CMD_SPANK  ="Spank";
string K_CMD_KISS ="Kiss";
string K_CMD_ASK_FOR_SPANK ="Request spank";
string K_CMD_ARTISTIC ="Artistic";
string K_CMD_ASK_FOR_DANCE = "Ask for dance";
string K_CMD_INTIMACY = "Intimacy";
String K_CMD_ASK_FOR_SPECIAL_REQUEST ="Special Request";
String K_CMD_CANCEL = "Too bad, cancel";

////////////////////////////////////
// variables
////////////////////////////////////
integer debugMode = 1;
integer dialogListenHandle = 0;


////////////////////////////////////
// log function
////////////////////////////////////
debug (string pLog) {
    if (debugMode == 1) {
        llSay(DEBUG_CHANNEL,llGetScriptName()  + ":" + pLog);
    }
}

////////////////////////////////////
// Spank action
////////////////////////////////////
spank (key touchingKey){

  string origName = llGetObjectName();
  llStartAnimation("asslap");
  llPlaySound( "spankmoan", 1.0 );

  llSetObjectName(" ");
  llSay(PUBLIC_CHANNEL, llGetDisplayName(touchingKey) + " spanks " + llGetDisplayName(ownerKey) + "'s ass.");
  llSetObjectName(origName);
}

////////////////////////////////////
// sentence action
////////////////////////////////////
actionSentence (key touchingKey, String sentence){

  string origName = llGetObjectName();
  llSetObjectName(" ");
  llSay(PUBLIC_CHANNEL, sentence);
  llSetObjectName(origName);
}

////////////////////////////////////
// Default state
////////////////////////////////////

default
{
    state_entry()
    {
        llRequestPermissions(llGetOwner(), PERMISSION_TRIGGER_ANIMATION);
        dialogListenHandle = llListen(K_CHANNEL_SPANKER, "", idx, "");
    }

    on_rez(integer start_param)
    {
        llResetScript();
    }

    changed(integer iChange){
        // script is resetted each time the owner changes
        // or link between prims change
        if (iChange & (CHANGED_OWNER|CHANGED_LINK)) {
            resetScript();
        }
    }

    touch_start(integer total_number)
    {

        key idx = llDetectedKey(0);
        key  ownerKey= llGetOwner();

        if (touchingKey != ownerKey) {
          llInstantMessage(llGetOwner(), llGetDisplayName(idx) + " touched your butt.");
          menu += K_CMD_SPANK;
          menu += K_CMD_KISS;
          menu += K_CMD_ASK_FOR_SPANK;
          menu += K_CMD_ARTISTIC;
          menu += K_CMD_ASK_FOR_DANCE;
          menu += K_CMD_FONDLE;
          menu += K_CMD_INTIMACY;
          menu += K_CMD_ASK_FOR_SPECIAL_REQUEST;
          menu += K_CMD_CANCEL;

          llDialog(idx,
                    "Bring your Own Spanker version " + K_Version + "\n\nWelcome to Spanker, Eric Sorensen Special Edition.\nSelect your action.\n\n" + nameGms,
                    menu,
                    K_CHANNEL_SPANKER);
        }
    }

    listen(integer channel, string name, key id, string message) {

      // Handle chat cmd
      if (channel == K_CHANNEL_SPANKER){

        String sentence = "";
        if (message == K_CMD_SPANK) {
          spank(id);
        } else if (message == K_CMD_KISS) {
          sentence = llGetDisplayName(id) + " bends over " + llGetDisplayName(ownerKey) + "'s ass and kisses it sensuously.";
          actionSentence(id, sentence);
        } else if (message == K_CMD_ASK_FOR_SPANK) {
          sentence = llGetDisplayName(id) + " whispers in  " + llGetDisplayName(ownerKey) + "'s ear : a request to be spanked.";
          actionSentence(id, sentence);
        } else if (message == K_CMD_ARTISTIC {
          sentence = llGetDisplayName(id) + " draws erotic circles on  " + llGetDisplayName(ownerKey) + "'s ass, inspired by naughty thoughts.";
          actionSentence(id, sentence);
        } else if (message == K_CMD_ASK_FOR_DANCE {
          sentence = llGetDisplayName(id) + " grabs  " + llGetDisplayName(ownerKey) + "'s ass to ask him a lapdance.";
          actionSentence(id, sentence);
        } else if (message == K_CMD_FONDLE {
          sentence = llGetDisplayName(id) + " fondles  " + llGetDisplayName(ownerKey) + "'s ass in a sensuous way.";
          actionSentence(id, sentence);
        } else if (message == K_CMD_INTIMACY {
          sentence = llGetDisplayName(id) + " rubs her crotch against  " + llGetDisplayName(ownerKey) + "'s ass in a lascivious way.";
          actionSentence(id, sentence);
        } else if (message == K_CMD_ASK_FOR_SPECIAL_REQUEST) {
          sentence = llGetDisplayName(id) + " kisses  " + llGetDisplayName(ownerKey) + "'s ass and ask him to do naughty things but no, you will not know.";
          actionSentence(id, sentence);
        } else if (message == K_CMD_CANCEL) {
          sentence = llGetDisplayName(id) + " is tempted by  " + llGetDisplayName(ownerKey) + "'s ass, hesitates and finally decides that this is a no go. Is she too shy?";
          actionSentence(id, sentence);
        }

      }
    }


}
