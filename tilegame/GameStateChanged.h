//
//  GameState.h
//  tutorial_TileGame
//
//  Created by Jeremiah Anderson on 1/9/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DVConstants.h"

@interface GameStateChanged : NSObject
{
    // member variables
//    int melons[NUM_MELONS];
//    NSMutableArray* melons; //= [[NSMutableArray alloc] initWi; // array size will be NUM_MELONS from constants.h
    
//  NSMutableArray *itemarray = [[NSMutableArray alloc] initWithCapacity:60];  
   
    NSMutableArray* melons;  // array size will be NUM_MELONS from constants.h
    int numMelonsEaten;
    int positionX;
    int positionY;
    
}
    

// constructor // not shown in interface file

// destructor // not shown in interface file
@end
