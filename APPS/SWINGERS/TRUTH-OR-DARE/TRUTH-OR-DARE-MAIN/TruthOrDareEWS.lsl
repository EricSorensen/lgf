////////////////////////////////////////////////////////////////////////////////////////////////////
//
//
//  Lady Green Forensic Component     : TRUTH-OR-DARE
//
//  Signature                         : LGF/APPS/SWINGERS/TRUTH-OR-DARE/TRUTH-OR-DARE-MAIN
//  LGF Version protocol              : 1.0.0.0
//  Component version                 : 0.1
//  release date                      : March 2019
//
//  Description : This component is a version of truth or dare game
//
//
//  States description :
//      Default:
//          current state when object is rezzed. No game are engaged.
//
//      initialize:
//          Prepare for a game.
//
//      start:
//          Run the initialized game.
//
//
//  Messages sent by TRUTH-OR-DARE-MAIN (Please refer to LGF msg directory)
//
//  Message managed by TRUTH-OR-DARE-MAIN (Please refer to LGF msg directory)
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
string K_Version = "0.1.0.2"; // version of the component
integer K_CHAT_CHANNEL  = 1;
integer K_CHANNEL_ADMIN = 10;
integer K_CHANNEL_ADMIN_ADDUSER = 11;
integer K_CHANNEL_ADMIN_REMOVEUSER=12;
integer K_CHANNEL_DIALOG=13;
string K_CMD_INITIALIZE   = "initialize";
string K_CMD_REINITIALIZE = "reinit";
string K_CMD_SET_LEVEL    = "level";
string K_CMD_SET_LEVEL_0  = "entertainement";
string K_CMD_SET_LEVEL_1  = "sexy";
string K_CMD_SET_LEVEL_2  = "hot";
string K_CMD_START        = "start";
string K_CMD_STOP         = "stop";
string K_CMD_SKIP         = "skip";
string K_CMD_EJECT        = "eject";
string K_CMD_ADMIN_ADD    = "Add GM";
string K_CMD_ADMIN_REMOVE = "Remove GM";
string K_CMD_ADMIN_LIST   = "List GM";
string K_CMD_BACK         = "Back";
string K_CMD_CANCEL       = "Cancel";
string K_CMD_MAIN_ADMIN_MENU   = "Admin main menu";
string K_NOT_AUTHORIZED_CMD      = "Cmd not authorized";

////////////////////////////////////
// variables
////////////////////////////////////
integer debugMode = 1;
integer chatListenHandle;
integer dialogListenHandle;
integer dialogListenHandleAddUser;
integer dialogListenHandleRemoveUser;
list players=[];
list males=[];
list females=[];

integer indexPlayer;
key initiator;
string currentAdminCmd;
list authorizedGameMasters = [];

////////////////////////////////////
// log function
////////////////////////////////////
debug (string pLog) {
    if (debugMode == 1) {
        llSay(DEBUG_CHANNEL,llGetScriptName()  + ":" + pLog);
    }
}

////////////////////////////////////
// randomize function
////////////////////////////////////
float randBetween(float min, float max) {
  return llFrand(max - min) + min;
}

////////////////////////////////////
// resetcript function
////////////////////////////////////
resetScript() {
  // on reset le script
  llResetScript();

  // reinit all variables
  players= [];
  males=[];
  females=[];
  loadingCard = 0;
  initiator=NULL_KEY;
  authorizedGameMasters = []+ llGetOwner();
  debug ("reset script. GM=" + llList2CSV(authorizedGameMasters));

  // Close the listen port
  llListenRemove(chatListenHandle);

}


/***************************************************************
** Check unicity of subscriber whether it is a male or a female
****************************************************************/
list processCmd (key id, string origcmd) {
  list returnValue = [];

  // check if avatar that sent the request is an authorized initiator
  list values = [] + id;
  integer index = llListFindList(authorizedGameMasters, values);
  if (index >= 0) {
    // log
    debug ("cmd reçue:" + origcmd);

    // we trim the cmd
    string cmd = llStringTrim(origcmd, STRING_TRIM);

    // we deal with lowercase strings only.
    cmd = llToLower(cmd);

    // we build a list of parameters
    returnValue = llParseString2List(cmd, [" "], []);

    // log
    debug ("cmd parsée:" + llList2CSV(returnValue));
  } else {
    returnValue = [] + K_NOT_AUTHORIZED_CMD;
    string idName = llGetDisplayName(id);
    llInstantMessage(id, idName + ", Stranger, you're not authorized to initiate, start, stop a game or change settings ");
  }

  return returnValue;
}

/***************************************************************
** Check unicity of subscriber whether it is a male or a female
****************************************************************/
processAdminCmd(key id, string message) {
  // check if avatar that sent the request is an authorized initiator
  list values = [] + id;
  integer index = llListFindList(authorizedGameMasters, values);
  debug(llList2CSV(authorizedGameMasters));
  debug ("Valeur de index: " + (string)index);
  if (index >= 0) {
    // gérer les commandes de premier et de deuxième niveau.
    if (message == K_CMD_ADMIN_ADD) {
      currentAdminCmd = K_CMD_ADMIN_REMOVE;
      llTextBox(id,﻿ "Type the id key of avatar you want to add as a game master.", K_CHANNEL_ADMIN_ADDUSER);﻿
      dialogListenHandleAddUser = llListen(K_CHANNEL_ADMIN_ADDUSER, "", id, "");
    } else if (message == K_CMD_ADMIN_REMOVE) {
      currentAdminCmd = K_CMD_ADMIN_REMOVE;

      integer i = 1;
      integer nbGameMasters = llGetListLength(authorizedGameMasters);
      list gms = [];
      string nameGms;
      for (i=1; i<nbGameMasters; i++){
          gms += (string)i;
          nameGms +=  (string)i + ":" + llGetDisplayName(llList2Key(authorizedGameMasters, i)) + "\n";
      }

      dialogListenHandleRemoveUser = llListen(K_CHANNEL_ADMIN_REMOVEUSER, "", id, "");
      list menu = gms;
      menu += K_CMD_BACK;
      menu += K_CMD_CANCEL;

      llDialog(llDetectedKey(i),
                "Truth or dare version " + K_Version + "\n\nWelcome to Truth or Dare, EWS RP Special Edition.\nSelect an avatar to remove.\n\n" + nameGms,
                menu,
                K_CHANNEL_ADMIN_REMOVEUSER);

    } else if (message == K_CMD_ADMIN_LIST) {
        //
        string gameMasters = "";
        integer i = 0;
        integer nbGameMasters = llGetListLength(authorizedGameMasters);

        for (i=0; i<nbGameMasters; i++){
            gameMasters = gameMasters + llGetDisplayName(llList2Key(authorizedGameMasters, i));
        }

        llInstantMessage(id, "Here's the list of all authorized game masters:\n"+gameMasters);

    } else if (message == K_CMD_CANCEL) {
      // Do nothing. We just close the window.
    } else if ((message == K_CMD_BACK) || (message == K_CMD_MAIN_ADMIN_MENU)) {
      // user is authorized to access the administration menu
      debug ("affichage du menu principal");
      list menu = [K_CMD_ADMIN_ADD, K_CMD_ADMIN_REMOVE, K_CMD_ADMIN_LIST];
      llDialog(id,
                "Truth or dare version " + K_Version + "\n\nWelcome to Truth or Dare, EWS RP Special Edition.\nAdministration menu.\n Choose your option to manage the game masters(GM) list.",
                menu,
                K_CHANNEL_ADMIN);

    } else {
      debug("unexpected admin cmd received: " + message);
    }
  }
}

/***************************************************************
** Add an avatar as a gameMaster
****************************************************************/
addAuthorizedGameMaster(key id, string UUIDToAdd) {
  // check if the key is valid
  key keytoAdd = (key) UUIDToAdd;
  string newGameMasterName = llGetDisplayName(keytoAdd);

  if (newGameMasterName==""){
    llInstantMessage(id, UUIDToAdd + " is an invalid id key. No avatar found and added as a new game master.");
  } else {
    // this is a valid key. We add it
    authorizedGameMasters += keytoAdd;
    llInstantMessage(id, newGameMasterName + " has been added to the authorized game masters list.");
  }
}

/***************************************************************
** Remove an avatar as a gameMaster
****************************************************************/
removeAuthorizedGameMaster(key id, string indexToRemove) {

  integer index = (integer) indexToRemove;

  if (index < llGetListLength(authorizedGameMasters) ) {
    key removedGM = llList2Key(authorizedGameMasters, index);
    string removedGMName = llGetDisplayName(removedGM);
    llDeleteSubList(authorizedGameMasters, index, index);
    llInstantMessage(id, " has been removed from the authorized game masters list.");
  }
}

/***************************************************************
** Check unicity of subscriber whether it is a male or a female
** return FALSE if the key change subscribe. TRUE otherwise
****************************************************************/
integer isKeyAlreadyRegistered (key subscriberId) {
  integer returnValue = TRUE;

  // Verify unicity of subscriber
  list value = [] + subscriberId;
  // check in males list
  integer index = llListFindList(males, value);
  if (index == -1) {
    // not find in males list. Check in females list
    index = llListFindList(females, value);
    if (index == -1) {
    // not find in females list either. Not already registered
      returnValue = FALSE;
    }
  }

  return returnValue;
}

/***************************************************************
** Reinitialize game
****************************************************************/
reinitGame () {
  males=[];
  females=[];
  llSetText("Initializing game...",<1.0,1.0,1.0>,1.0);
  llSay(PUBLIC_CHANNEL, "Truth or Dare, EWS RP Special Edition. Be nice but be naughty!\nInitializing a new game of Truth or Dare for your fun.");
  setLevel(K_CMD_SET_LEVEL_0);
}

/***************************************************************
** start game
****************************************************************/
startGame () {
  key aviKey = llList2Key(players, 0);

  llSay(PUBLIC_CHANNEL, "Truth or Dare, EWS RP Special Edition. Be nice and be naughty!\nStarting the game. New players can still join by clicking on me.\nIn game players clicks on me when this is their turn.");

  string firstPlayerName = llGetDisplayName(aviKey);

  llSetText( "First player is " + firstPlayerName,<1.0,1.0,1.0>,1.0);
  llSay(PUBLIC_CHANNEL, "Waiting for the first player to click and play...");
  llInstantMessage(aviKey, "Stranger " + firstPlayerName + ", you are the first player. Remember, these walls have ears. No lie is possible.");

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

  initNotecard(getNotecardName());

}

/***************************************************************
** shuffle and prepare the game
****************************************************************/
shuffleAndPrepareGame() {
    // shuffle the users
    // By default males will begin
    integer firstGender = 0;
    integer totalRound = 0;
    players=[];
    males = llListRandomize(males, 1);
    females = llListRandomize(females, 1);

    debug ("Entrée shuffleAndPrepareGame:Nombre de joueurs :" + (string)llGetListLength(players));

    // order players
    if (llGetListLength(males) == llGetListLength(females)){
      // same number of males and females. Throw a dice to
      // determine who begins
      float rnd = randBetween(0.0, 1.0);
      if (rnd> 0.5){
          // female will begin
          firstGender = 1;
      }
      totalRound = llGetListLength(males);
    } else if (llGetListLength(males) < llGetListLength(females)){
      // female will begin
      firstGender = 1;
      totalRound = llGetListLength(females);
    } else {
      totalRound = llGetListLength(males);
    }

    integer i;
    // create the ordered list of players
    for(i = 0; i < totalRound; i++){
      if (firstGender==1){
        players += llList2Key(females, i) ;
        debug ("Adding as male player: " + (string)llList2Key(females, i));
        if (i<llGetListLength(males)){
          players += llList2Key(males, i) ;
          debug ("Adding as male player: " + (string)llList2Key(males, i));
        }
      } else {
        players += llList2Key(males, i) ;
        debug ("Adding as male player: " + (string)llList2Key(males, i));
        if (i<llGetListLength(females)){
          players += llList2Key(females, i);
          debug ("Adding as female player: " + (string)llList2Key(females, i));
        }
      }
    }
    debug ("Sortie shuffleAndPrepareGame:Nombre de joueurs :" + (string)llGetListLength(players));

    //shuffles the questions.
    shuffleQuestionsAndActions();
}


/***************************************************************
** Check if a key can join the game.
****************************************************************/
integer subscribeUserIfAvailable(integer channel, key id, string message) {
  integer returnCode = 1;
  // Handle the response menu to select the gender

  if (message=="male") {
    if (isKeyAlreadyRegistered(id)==FALSE) {
      males += id;
      llSay(PUBLIC_CHANNEL, llGetDisplayName(id) + " (M) joined the game.");

    } else {
      returnCode = 0;
      llSay(PUBLIC_CHANNEL, llGetDisplayName(id) + "? Stranger? You're already registered. Be patient: the game will begin soon.");
    }

  } else if (message="female") {
    if (isKeyAlreadyRegistered(id)==FALSE) {
      females += id;
      llSay(PUBLIC_CHANNEL, llGetDisplayName(id) + " (F) joined the game.");
    } else {
      returnCode = 0;
      llSay(PUBLIC_CHANNEL, llGetDisplayName(id) + "? Stranger? You're already registered. Be patient: the game will begin soon.");
    }
  }

  return returnCode;
}

/***************************************************************
** Assign the next player
****************************************************************/
assignNextPlayer(){

  debug ("increment indexPlayer:" + (string)indexPlayer);
  if (indexPlayer >= llGetListLength(players)){
    // all player have player the round. Reinit the round
    indexPlayer = 0;
  }

  debug ("calcul indexPlayer:" + (string)indexPlayer);
  debug ("Nombre de joueurs :" + (string)llGetListLength(players));

  // Now incrementing the next question
  indexQA++;
  if (indexQA >= llGetListLength(qaOneGame)){
    // all questions have been asked. Propose the change the level
    indexQA = 0;
    llSay(PUBLIC_CHANNEL, "Truth or Dare, EWS RP Special Edition. Pool of questions exhausted for this level. We suggest you to change the level of sexiness... or jump in your bed for hotter things.");
  }
}

/***************************************************************
** Skip the current player. Go immeediately to next player.
****************************************************************/
ejectPlayer(){
  players = llDeleteSubList(players, indexPlayer, indexPlayer);
  assignNextPlayer();

  if (llGetListLength(players)==0) {
    llSay(PUBLIC_CHANNEL, "Truth or Dare, EWS RP Special Edition. Last player left. Game ended.");

    // reinit the game
    state default;
  }
}

/***************************************************************
** Skip the current player. Go immeediately to next player.
****************************************************************/
sKipCurrentPlayer() {
  // Now incrementing the next user
  indexPlayer++;
  assignNextPlayer();
}

/***************************************************************
** Ask a question to the current player
****************************************************************/
askToUser(){
  debug ("Entrée askToUser:Nombre de joueurs :" + (string)llGetListLength(players));

  key aviKey = llList2Key(players, indexPlayer);
  string aviName = llGetDisplayName(aviKey);
  string question = llList2String(qaOneGame, indexQA);

  llSay(PUBLIC_CHANNEL, aviName + ", " + question);

  // Now incrementing the next user
  indexPlayer++;
  assignNextPlayer();
}


/////////////////////////////////////////////////////
// default state of this script : no game are running
/////////////////////////////////////////////////////
default
{
    // state initialization method
    state_entry() {
      // initialize default GM
      authorizedGameMasters = []+ llGetOwner();

      llSay(PUBLIC_CHANNEL, "Waiting for a new EWS game to start.");
      llSetText("Waiting for a new game to start...",<1.0,1.0,1.0>,1.0);

      // we define the notecard lists that maybe loaded to play
      initNotecardNames();
      chatListenHandle = llListen(K_CHAT_CHANNEL, "", NULL_KEY, K_CMD_INITIALIZE);
      dialogListenHandle = llListen(K_CHANNEL_ADMIN, "", "", "");

    }

    listen(integer channel, string name, key id, string message) {

      if (channel == K_CHANNEL_ADMIN) {
        processAdminCmd(id, message);
      } else  if (channel == K_CHANNEL_ADMIN_ADDUSER){
        llListenRemove(dialogListenHandleAddUser);
        dialogListenHandleAddUser = 0;
        addAuthorizedGameMaster(id, message);
      } else  if (channel == K_CHANNEL_ADMIN_REMOVEUSER){
        llListenRemove(dialogListenHandleRemoveUser);
        dialogListenHandleRemoveUser = 0;
        removeAuthorizedGameMaster(id, message);
      } else {

        // No need to filter by channel. the state is listening only
        // one channel.
        list cmd = processCmd(id, message);

        if (llList2String(cmd, 0)== K_CMD_INITIALIZE){
            // player that initiated the game become the initiator
            // Only her or him will be able to change the settings.
            initiator = id;

            // transition vers l'état Initialize
            state initialize;
        }
      }
    }

    touch_start(integer total_number) {
      integer i = 0;
      debug ("touch in default state");
      for(i=0; i < total_number; ++i) {
        processAdminCmd(llDetectedKey(i), K_CMD_MAIN_ADMIN_MENU);
      }
    }

    changed(integer iChange){
        // script is resetted each time the owner changes
        // or link between prims change
        if (iChange & (CHANGED_OWNER|CHANGED_LINK)) {
            resetScript();
        }
    }

    on_rez(integer param){
        // reset the script each time the object is rezzed
        resetScript();
    }

}

/////////////////////////////////////////////////////
// initialize state : Ready to prepare the game
/////////////////////////////////////////////////////
state initialize {
    // state initialization method
    state_entry() {
      chatListenHandle = llListen(K_CHAT_CHANNEL, "", initiator, "");
      dialogListenHandle = llListen(K_CHANNEL_DIALOG, "", NULL_KEY, "");
      reinitGame();
    }

    touch_start(integer total_number) {
      integer i = 0;

      list menu = ["male", "female"];
      for(i=0; i < total_number; ++i) {
          // Open a dialog for each avatar that touched the prim
          llDialog(llDetectedKey(i), "Truth or dare version " + K_Version + "\n\nWelcome to Truth or Dare, EWS RP Special Edition.\nPlease choose your gender.", menu, K_CHANNEL_DIALOG);
        }
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

            // open the chat channel. once the notecard is loaded successfully
            chatListenHandle = llListen(K_CHAT_CHANNEL, "", llGetOwner(), "");

          }
      }
    }

    listen(integer channel, string name, key id, string message) {
      if (channel == K_CHANNEL_DIALOG) {
        subscribeUserIfAvailable(channel, id, message);
      }

      // Handle chat cmd
      if (channel == K_CHAT_CHANNEL){
        list cmd = processCmd(id, message);

        debug ("Nombre de token dans la commande : " + (string)llGetListLength(cmd));
        if (llList2String(cmd, 0) == K_CMD_START){

          shuffleAndPrepareGame();

          // start the game. Listen are automatically removed
          state start;
        }

        if (llList2String(cmd, 0)== K_CMD_REINITIALIZE){
          // reinit the game
          reinitGame();
        }

        if (llList2String(cmd, 0)== K_CMD_SET_LEVEL){
          if (llGetListLength(cmd)==2) {
            // set level to those requested
            setLevel(llList2String(cmd, 1));
          } else {
            llInstantMessage(initiator, "To set the level, you should provide one level, either entertainement, sexy or hot.");
          }
        }

      }
    }

    changed(integer iChange){
        // script is resetted each time the owner changes
        // or link between prims change
        if (iChange & (CHANGED_OWNER|CHANGED_LINK)) {
            resetScript();
        }
    }

    on_rez(integer param){
        // reset the script each time the object is rezzed
        resetScript();
    }

}

/////////////////////////////////////////////////////
// start state : game is started
/////////////////////////////////////////////////////
state start
{

    // state initialization method
    state_entry() {
      debug ("Entrée state start");
      chatListenHandle = llListen(K_CHAT_CHANNEL, "", NULL_KEY, "");
      dialogListenHandle = llListen(K_CHANNEL_DIALOG, "", NULL_KEY, "");
      startGame();
    }

    touch_start(integer total_number) {
      integer i = 0;
      for(; i < total_number; ++i) {
        key aviKey = llDetectedKey(i);
        if (loadingCard==1) {
          llInstantMessage(aviKey, "Stranger, do not be so impatient! Questions are dares are loading. Please wait...");
        } else {
          if (llList2Key(players, indexPlayer) != aviKey) {
            // wrong user clicked to get a question. Is he/she already registered
            // or a requested from a new avatar to join the game?
            if (isKeyAlreadyRegistered(aviKey) == TRUE) {
              string playerName = llGetDisplayName(llDetectedKey(i));
              llSay(PUBLIC_CHANNEL, "Shame on you Stranger " + playerName + "! This is not your turn. Look at those pictures on the walls: they keep an eye on you.");
            } else {
              // launch the registering process
              list menu = ["male", "female"];
              llDialog(llDetectedKey(i), "Truth or dare version " + K_Version + "\n\nWelcome to Truth or Dare, , EWS RP Special Edition.\nYou can join the current game.\nPlease choose your gender.", menu, K_CHANNEL_DIALOG);
            }
          } else {
              //ask the Question
              askToUser();
              // set the timer to display the next user
              llSetTimerEvent(10.0);
          }
        }
      }
    }

    timer() {
      // stop timer to avoid lag
      llSetTimerEvent(0);
      // We display the name of the next player
      key aviKey = llList2Key(players, indexPlayer);
      string nextPlayerName = llGetDisplayName(aviKey);

      llSetText( "Next player is " + nextPlayerName,<1.0,1.0,1.0>,1.0);
      llInstantMessage(aviKey, nextPlayerName + "! Stranger! You are the next player. Be ready to be naughty for our pleasure.");
    }

    listen(integer channel, string name, key id, string message) {
      if (channel == K_CHANNEL_DIALOG) {
        debug ("Réception d'une demande d'ajout de joueur en cours de partie.");
        integer returnCode = subscribeUserIfAvailable(channel, id, message);

        if (returnCode == 1) {
          // add the user at the end of the list of users
          debug ("Joueur ajouté.");
          players += id;
        }

      }

      // Handle chat cmd
      if (channel == K_CHAT_CHANNEL){
        list cmd = processCmd(id, message);

        if (llList2String(cmd, 0)== K_CMD_SKIP){
          // skip the current player
          sKipCurrentPlayer();
          // set the timer to display the next user
          llSetTimerEvent(1.0);
        } else if (llList2String(cmd, 0)== K_CMD_EJECT){
          // eject the player from the game
          ejectPlayer();
          // set the timer to display the next user
          llSetTimerEvent(1.0);
        } else if (llList2String(cmd, 0)== K_CMD_STOP){
          // reinit the game
          state default;
        } else if (llList2String(cmd, 0)== K_CMD_REINITIALIZE){
          // reinit the game
          reinitGame();
        } if (llList2String(cmd, 0)== K_CMD_SET_LEVEL){
          if (llGetListLength(cmd)==2) {
            // set level to those requested
            debug ("change the level during the game");
            loadingCard = 1;
            setLevel(llList2String(cmd, 1));
          } else {

          }
        }

      }
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
            loadingCard = 0;
            shuffleQuestionsAndActions();
            llSay(PUBLIC_CHANNEL, (string)(ncLines) + " questions and dares have been loaded successfully.");
            // open the chat channel. once the notecard is loaded successfully
            chatListenHandle = llListen(K_CHAT_CHANNEL, "", llGetOwner(), "");

          }
      }
    }

    changed(integer iChange){
        // script is resetted each time the owner changes
        // or link between prims change
        if (iChange & (CHANGED_OWNER|CHANGED_LINK)) {
            resetScript();
        }
    }

    on_rez(integer param){
        // reset the script each time the object is rezzed
        resetScript();
    }

}
