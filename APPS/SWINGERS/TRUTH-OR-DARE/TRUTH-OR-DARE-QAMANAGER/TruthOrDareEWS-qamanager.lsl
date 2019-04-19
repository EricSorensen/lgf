////////////////////////////////////////////////////////////////////////////////////////////////////
//
//
//  Lady Green Forensic Component     : TRUTH-OR-DARE
//
//  Signature                         : LGF/APPS/SWINGERS/TRUTH-OR-DARE/TRUTH-OR-DARE-QAMANAGER
//  LGF Version protocol              : 1.0.0.0
//  Component version                 : 0.1
//  release date                      : April 2019
//
//  Description : This script stores qa from TRUTH-OR-DARE system and
//                display a question or a dare
//
//
//  States description :
//      Default:
//          current state when object is rezzed. No game are engaged.
//
//      readyToProcess:
//          accept request to change level or ask question.
//
//
//  Messages sent by TRUTH-OR-DARE-QAMANAGER (Please refer to LGF msg directory)
//
//  Message managed by TRUTH-OR-DARE-QAMANAGER (Please refer to LGF msg directory)
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

string K_MSG_SET_LEVEL       = "SET_LEVEL";
string K_MSG_GET_QA          = "GET_QA";
integer K_CHANNEL_STORAGE    = -6500;

string K_CMD_SET_LEVEL_0  = "entertainement";
string K_CMD_SET_LEVEL_1  = "sexy";
string K_CMD_SET_LEVEL_2  = "hot";

////////////////////////////////////
// variables
////////////////////////////////////
integer debugMode = 1;
list qaOneGame=[];
integer level=0;
integer ncLines=0;
string ncNotecardLevel0="";
string ncNotecardLevel1="";
string ncNotecardLevel2="";
key ncQueryId;
integer indexQA;


////////////////////////////////////
// log function
////////////////////////////////////
debug (string pLog) {
    if (debugMode == 1) {
        llSay(DEBUG_CHANNEL,llGetScriptName()  + ":" + pLog);
    }
}

/***************************************************************
** Set Level
****************************************************************/
setLevel (string slevel) {

  llSay(PUBLIC_CHANNEL, "Loading questions and dares. Please wait...");

  if (slevel == K_CMD_SET_LEVEL_0) {
    level = 0;
    llSay(PUBLIC_CHANNEL, "Level set to " + K_CMD_SET_LEVEL_0);
  } else if (slevel == K_CMD_SET_LEVEL_1) {
    level = 1;
    llSay(PUBLIC_CHANNEL, "Level set to " + K_CMD_SET_LEVEL_1);
  } else if (slevel == K_CMD_SET_LEVEL_2) {
    level = 2;
    llSay(PUBLIC_CHANNEL, "Level set to " + K_CMD_SET_LEVEL_2);
  } else {
    llSay(PUBLIC_CHANNEL, "Cannot set level. Please choose between " + K_CMD_SET_LEVEL_0 + ", " + K_CMD_SET_LEVEL_1 + ", " + K_CMD_SET_LEVEL_2 + ".");
  }
}

/***************************************************************
** Read the notecards to initialize questions and actions
****************************************************************/
initNotecard(string ncName){

  // clean all records
  ncLines = 0;
  qaOneGame = [];

  debug ("démarrage processus chargement notecard "+ ncName);
  ncQueryId = llGetNotecardLine(ncName,ncLines);

  // we remove the capacity to execute command until the notecard is loaded
  llListenRemove(chatListenHandle);
}

/***************************************************************
** get the notecardName depending of the current level
****************************************************************/
string getNotecardName(){
  string ncName;

  if (level == 0) {
    ncName = ncNotecardLevel0;
  } else if (level == 1) {
    ncName = ncNotecardLevel1;
  } else if (level == 2){
    ncName = ncNotecardLevel2;
  } else {
    llInstantMessage(initiator, "Invalid Level to load notecard : " + (string)level);
  }

  return ncName;
}

/***************************************************************
** shuffle the questions and actions for a new geme ou a new level
****************************************************************/
shuffleQuestionsAndActions(){

    // shuffle questions and actions
    qaOneGame = llListRandomize(qaOneGame, 1);
}

/***************************************************************
** reinit variables after a notecard has been processed
****************************************************************/
postProcessNotecard() {

  ncLines=0;
  key ncQueryId = NULL_KEY;
  indexQA = 0;;
}

/***************************************************************
** Read one line of the notecard to load
****************************************************************/
readnotecardLine(string lineCard) {
  // tokenize the card line
  list line = llParseString2List(lineCard, ["|"], []);

  // a line should contain 2 and only 2 tokens
  if (llGetListLength(line)!=2) {
    llInstantMessage(initiator, "line " + (string)ncLines + " is invalid. 2 tokens are expected: " + lineCard);
  } else {
    // process the card line
    string lineType= llToLower(llList2String(line,0));
    string lineLabel= llList2String(line,1);

    if ((lineType != "q") && (lineType != "a")){
      llInstantMessage(initiator, "line " + (string)ncLines + " is invalid. type should be 'a' or 'q': " + lineCard);
    } else {
      qaOneGame += lineLabel;
    }
  }
}

/***************************************************************
** Init the notecard names
****************************************************************/
initNotecardNames(){
  string notecardName;
  string prefix;
  integer n = llGetInventoryNumber(INVENTORY_NOTECARD);
  integer i = 0;

  while (i < n){
    notecardName = llGetInventoryName(INVENTORY_ALL, i);
    prefix = llGetSubString(notecardName, 0, 5);
    if (prefix=="qa-ent"){
        ncNotecardLevel0 = notecardName;
    } else if (prefix=="qa-sex"){
      ncNotecardLevel1 = notecardName;
    } else if (prefix=="qa-hot"){
      ncNotecardLevel2 = notecardName;
    }
    i++;
  }

  // check if all notecards have been found
  if (ncNotecardLevel0==""){
    llInstantMessage(initiator, "Warning: No entertainement notecard found.");
  }

  if (ncNotecardLevel1==""){
    llInstantMessage(initiator, "Warning: No sexy notecard found.");
  }

  if (ncNotecardLevel2==""){
    llInstantMessage(initiator, "Warning: No hot notecard found.");
  }

}


////////////////////////////////////
// get a QA
////////////////////////////////////
getQA(key id) {
  string question = "";

  if (indexQA < llGetListLength(qaOneGame)){
    question = llList2String(qaOneGame, indexQA);

    // ask question or dare
    string aviName = llGetDisplayName(id);
    llSay(PUBLIC_CHANNEL, aviName + ", " + question);

    // Now incrementing the next question
    indexQA++;
  }

  if (indexQA >= llGetListLength(qaOneGame)){
    // all questions have been asked. Propose the change the level
    indexQA = 0;
    llSay(PUBLIC_CHANNEL, "Truth or Dare, EWS RP Special Edition. Pool of questions exhausted for this level. We suggest you to change the level of sexiness... or jump in your bed for hotter things.");
  }
}

////////////////////////////////////
// default state
////////////////////////////////////
default{
  state_entry() {
    // we define the notecard lists that maybe loaded to play
    initNotecardNames();

    // Init the questions and dares with default level
    initNotecard(getNotecardName());
  }

  dataserver(key queryId, string data) {
    // Process the card lines
    if(queryId == ncQueryId)
    {
        if(data != EOF)
        {
            readnotecardLine(data);
            ncQueryId = llGetNotecardLine(getNotecardName(),++ncLines);
        } else {

          llSay(PUBLIC_CHANNEL, (string)(ncLines) + " questions and dares have been loaded successfully.");
          llSay(PUBLIC_CHANNEL, "Truth or Dare. Let others be nice and be naughty!\nClick to join the game.");

          // notecard is loaded. Wait for requests.
          postProcessNotecard();
          state readyToProcess;

        }
    }
  }

}

state readyToProcess {
  state_entry() {

  }

  // Processing requests from parent script
  link_message(integer sender, integer canal, string message, key id) {
    if (canal == K_CHANNEL_STORAGE) {
      // Message is for the storage Component
      if (message == K_MSG_SET_LEVEL) {
        // this is a request to change the level
        debug("Receive a request change the level : " + (string)id);
        setLevel((string)id);
        state default;
      } else if (message == K_MSG_GET_QA) {
        // this is a request to get a question or a dare
        debug("Receive a request to get a QA.");
        getQA((key) id);
      }
    }
  }
}
