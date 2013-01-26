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
@synthesize previousPosition = _previousPosition;
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
                                         [NSString stringWithFormat:@"P%d", self.owner.uniqueID+1], kDVEventKey_OwnerID,
                                         nil]];
    return eventData;
}

@end
