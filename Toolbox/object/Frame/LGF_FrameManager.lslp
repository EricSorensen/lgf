////////////////////////////////////////////////////////////////////////////////////////////////////
//
//
//  Lady Green Forensic Component     : MEDIA RING
//
//  Signature                         : LGF/TBOX//OBJ/FRAME
//  LGF Version protocol              : 1.0.0.0
//  Component version                 : 0.10
//  release date                      : January 2016
//
//  Description : This component displays a list of pictures in a frame
//					Pictures must de thrown in prim inventory
//
//  State description : Defaut is the only state used
//						
//
//  Messages sent by FRAME : None
//
//  Message managed by FRAME : None
//
//
//  documentation : http://lgfsite.wordpress.com
///////////////////////////////////////////////////////////////////////////////////////////////////

list gPictures;
integer gIndex;

string PIC_PREFIX = "PIC";
float DELAY = 30.0;

string StringLeft(string source, integer length){
	
    return llToUpper(llGetSubString(source, 0, length - 1));
}


init() {
	gPictures = [];
	gIndex = 0;
	
	integer lNum = llGetInventoryNumber(INVENTORY_ALL);
	integer i = 0;
	string name;
	
	for (i = 0; i < lNum; ++i) {
		name = llGetInventoryName(INVENTORY_ALL, i);
           
		if (StringLeft(name, llStringLength(PIC_PREFIX)) == PIC_PREFIX) {
			
			gPictures += name;
        }
	}
	
	llSetTimerEvent(DELAY);

}

default {
    state_entry() {
        llOwnerSay("Hello Scripter");
    }

	timer(){
		gIndex = gIndex + 1;
		if (gIndex >= llGetListLength(gPictures)) {
			gIndex = 0;
		}
		
		string lPicName = llList2String(gPictures, gIndex);
		
		llSetTexture(lPicName, 0);
	}
    
    changed(integer change) {
       if (change & CHANGED_INVENTORY) {
       		// we reset the scripts to update the list of pics
           llResetScript();
       }
       if (change & CHANGED_TEXTURE)
       {
           //llOwnerSay("Les textures ou leurs attributs ont changé.");
       }
   }
}
