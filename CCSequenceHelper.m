//
//  CCSequenceHelper.m
//  tilegame2
//
//  Created by Jeremiah Anderson on 1/31/13.
//
//

#import "CCSequenceHelper.h"

@implementation CCSequenceHelper

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