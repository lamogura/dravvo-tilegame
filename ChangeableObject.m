//
//  ChangeableObject.m
//  tilegame2
//
//  Created by Jeremiah Anderson on 1/25/13.
//
//

#import "ChangeableObject.h"

@implementation ChangeableObject

@synthesize historicalEventsList_local;

- (id)init
{
    self = [super init];
    if (self) {
        historicalEventsList_local = [[NSMutableArray alloc] init];
    }
    return self;
}

-(void) performHistoryAtTimeStepIndex:(int) theTimeStepIndex {
    // FIX do shit
}
@end
