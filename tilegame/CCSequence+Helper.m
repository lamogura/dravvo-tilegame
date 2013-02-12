//
//  CCSequence+Helper.m
//  dravvo-tilegame_master
//
//  Created by Jeremiah Anderson on 1/23/13.
//
//

#import "CCSequence+Helper.h"

@implementation CCSequence (Helper)

+(id) actionMutableArray: (NSMutableArray *)actionList
{
	CCFiniteTimeAction *now;
	CCFiniteTimeAction *prev = [actionList objectAtIndex:0];
    
	for (int i = 1 ; i < [actionList count] ; i++) {
		now = [actionList objectAtIndex:i];
		prev = [CCSequence actionOne: prev two: now];
	}
	return prev;
}

@end
