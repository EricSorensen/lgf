////////////////////////////////////////////////////////////////////////////////////////////////////
//
//
//  Lady Green Forensic Component : BOX LETTER 
//
//  release date : September 2016
//
//  Description : 
//					
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


default
{
    state_entry()
    {
        llAllowInventoryDrop(TRUE);
    }

    changed(integer change)
    {
        //PUBLIC_CHANNEL has the integer value 0
        if (change & (CHANGED_ALLOWED_DROP | CHANGED_INVENTORY))
            llSay(PUBLIC_CHANNEL, "Your letter has been sent to Eric Sorensen");
            
        if (change & (CHANGED_OWNER | CHANGED_INVENTORY))
            llResetScript();
    }
    
    
}

