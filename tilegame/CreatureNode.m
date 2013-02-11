//
//  CreatureNode.m
//  tilegame
//
//  Created by mogura on 1/26/13.
//
//

#import "CreatureNode.h"

@implementation CreatureNode

@synthesize speedInPixelsPerSec = _speedInPixelsPerSec;
@synthesize behavior = _behavior;
//@synthesize previousPosition = _previousPosition;
@synthesize owner = _owner;
@synthesize entityType = _entityType;

-(id)initInLayer:(CoreGameLayer *)layer atSpawnPoint:(CGPoint)spawnPoint withBehavior:(DVCreatureBehavior)behavior ownedBy:(EntityNode *)owner
{
    if (self = [super initInLayer:layer atSpawnPoint:spawnPoint]) {
        self->_behavior = behavior;
        self->_owner = owner;
    }
    return self;
}

-(NSMutableDictionary *)cacheStateForEvent:(DVEventType)event {
    NSMutableDictionary* eventData = [super cacheStateForEvent:event];
    [eventData addEntriesFromDictionary:[NSDictionary dictionaryWithObjectsAndKeys:
                                         [NSNumber numberWithInt:self.owner.uniqueID], kDVEventKey_OwnerID,
                                         nil]];  // was self.owner.uniqueID + 1
    return eventData;
}

/*
// push all animations onto the NSMuttable Actions array
-(void)animateMove:(CGPoint) targetPoint  // will animate a historical move over time interval kTimeStepSeconds
{
    [super animateMove:targetPoint];
}
*/

@end
