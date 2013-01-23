//
//  CCSequence+Helper.m
//  dravvo-tilegame_master
//
//  Created by Jeremiah Anderson on 1/23/13.
//
//

#import "CCSequence+Helper.h"

@implementation CCSequence (Helper)

+(id) actionMutableArray: (NSMutableArray*) _actionList {
	CCFiniteTimeAction *now;
	CCFiniteTimeAction *prev = [_actionList objectAtIndex:0];
    
	for (int i = 1 ; i < [_actionList count] ; i++) {
		now = [_actionList objectAtIndex:i];
		prev = [CCSequence actionOne: prev two: now];
	}
    
	return prev;
}

@end
