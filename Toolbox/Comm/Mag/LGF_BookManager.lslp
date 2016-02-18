////////////////////////////////////////////////////////////////////////////////////////////////////
//
//
//  Lady Green Forensic Component     : MAG
//
//  Signature                         : LGF/TBOX/COMM/MAG
//  LGF Version protocol              : None
//  Component version                 : 0.10
//  release date                      : February 2016
//
//  Description : This script is a very simple script to animate a magazine worn as a Hud
//
//  State description : Defaut is the only state used 
//
//  Messages sent by MAG (Please refer to LGF msg directory)
//
//  Message managed by MAG (Please refer to LGF msg directory)
//
//
//  documentation : http://lgfsite.wordpress.com
///////////////////////////////////////////////////////////////////////////////////////////////////
 
integer     count = 0;
integer     primIndex;
float       offsetPageSpine;
float       angle;

integer     gSpineIndex;
string      kSpineName = "Spine";


positionPageToBack(integer primIndex) {
    list Params = llGetLinkPrimitiveParams(primIndex, [PRIM_POS_LOCAL]);
    vector posPage = llList2Vector(Params,0);
    
    Params = llGetLinkPrimitiveParams(gSpineIndex, [PRIM_SIZE]);
    vector sizeAxe =  llList2Vector(Params,0);
    
    posPage.x = posPage.x + (sizeAxe.x + offsetPageSpine) + 0.035;

    // Execute a translation
    llSetLinkPrimitiveParamsFast(primIndex, [ PRIM_POS_LOCAL, posPage]);

 }

bringPageToFront (integer primIndex) {
    list Params = llGetLinkPrimitiveParams(primIndex, [PRIM_POS_LOCAL]);
    vector posPage = llList2Vector(Params,0);
    
    Params = llGetLinkPrimitiveParams(gSpineIndex, [PRIM_POS_LOCAL, PRIM_SIZE]);
    vector posAxe =  llList2Vector(Params,0);
    vector sizeAxe =  llList2Vector(Params,1);
    
    float posPageTemp = posPage.x;
    posPage.x = posAxe.x- (sizeAxe.x/2) -0.02;
    offsetPageSpine =  posPage.x - posPageTemp;

    // Execute a translation
    llSetLinkPrimitiveParamsFast(primIndex, [ PRIM_POS_LOCAL, posPage]);

}

// this function turn the page primIndex with an angle angle
animate(float angle, integer primIndex) {

    // Retrieve position, size and rotation of the page to turn
    list Params = llGetLinkPrimitiveParams(primIndex, [PRIM_POS_LOCAL, PRIM_ROT_LOCAL, PRIM_SIZE]);
    vector posPage = llList2Vector(Params,0);
    rotation rotPage = llList2Rot(Params, 1);
    vector width = llList2Vector(Params,2);
    vector pageWidth = <0, width.y, .0>;
    
    // get the position of the spine book
    Params = llGetLinkPrimitiveParams(gSpineIndex, [PRIM_POS_LOCAL,PRIM_SIZE]);
    vector posAxe =  llList2Vector(Params,0);
    vector sizeAxe =  llList2Vector(Params,1);
    
    posAxe.x = posAxe.x - (sizeAxe.x/2) - 0.02;
    
    // computer the off-center rotation
    rotation rot = llEuler2Rot(<.0, .0, DEG_TO_RAD * angle>);
    vector transVector =  posPage - posAxe;
    vector rotVector = transVector * rot;
    vector newPosition = posAxe + rotVector;

    // Execute a off-center rotation   
    llSetLinkPrimitiveParamsFast(primIndex, [PRIM_ROT_LOCAL, rot * rotPage, PRIM_POS_LOCAL, newPosition]);
}

// this function initializes the script
// it looks for the sprine linked prim
init() {
    integer nbLinkedPrims = llGetNumberOfPrims();
    integer index = 0;
   
    gSpineIndex = -1;
       
    while (index < nbLinkedPrims) {
        if ( llGetLinkName (index) == kSpineName) {
            gSpineIndex = index;
            jump break;    
        } else {
            index = index + 1;
        }
    }
    @break;
    
    if (gSpineIndex == -1) {
        llOwnerSay("Error : No Linked prim called 'Spine' in this book.");
    }
    
}

default {
    state_entry(){
        init();
    }
    
    touch_start(integer total_number) {
        if(count == 0) {
            count = 0;
            
            primIndex =  llDetectedLinkNumber(0);
            integer face = llDetectedTouchFace(0);
            
            if (face == 2 ){
                angle = 20.0;
            } else {
                angle = -20.0;
            }
            
            bringPageToFront(primIndex);
            animate(angle, primIndex);
            llSetTimerEvent(0.15);
        }
       
    }
    
    timer(){
       count = count + 1;

       if (count == 9) {
            // we stop the animation because it rotates of 180 degrees
            count = 0;
            llSetTimerEvent(0);
            positionPageToBack(primIndex);
       } else {
            animate(angle, primIndex);
       }
    }    
    
    changed( integer change ) {
        if(change & (CHANGED_OWNER | CHANGED_INVENTORY|CHANGED_LINK)){
            llResetScript();
        }
    } 
}

