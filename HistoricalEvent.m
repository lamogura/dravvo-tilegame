//
//  HistoricalEvent.m
//  tilegame2
//
//  Created by Jeremiah Anderson on 1/25/13.
//
//

#import "HistoricalEvent.h"

@implementation HistoricalEvent

@synthesize timeStepIndex, action, entityType, entityIDNumber, coordX, coordY;

- (id)init
{
    self = [super init];
    if (self) {
        // nothing here
    }
    return self;
}

@end
