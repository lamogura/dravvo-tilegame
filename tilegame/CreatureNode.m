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
@synthesize owner = _owner;
@synthesize entityType = _entityType;

-(id)initInLayerWithoutCache:(CoreGameLayer *)layer atSpawnPoint:(CGPoint)spawnPoint withBehavior:(DVCreatureBehavior)behavior ownedBy:(EntityNode *)owner
{
    if (self = [super initInLayerWithoutCache:layer atSpawnPoint:spawnPoint]) {
        self->_behavior = behavior;
        self->_owner = owner;
    }
    return self;

}

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

- (void)encodeWithCoder:(NSCoder *)coder
{
    [super encodeWithCoder:coder];

    [coder encodeInt:self.speedInPixelsPerSec forKey:CreatureNodeSpeedInPixelsPerSec];
    [coder encodeInt:(int)self.behavior forKey:CreatureNodeBehavior];
    [coder encodeObject:self.owner forKey:CreatureNodeOwner];
}

- (id)initWithCoder:(NSCoder *)coder
{
    if (self = [super initWithCoder:coder])
    {
        _speedInPixelsPerSec = [coder decodeIntForKey:CreatureNodeSpeedInPixelsPerSec];
        _behavior = (DVCreatureBehavior)[coder decodeIntForKey:CreatureNodeBehavior];
        _owner = [coder decodeObjectForKey:CreatureNodeOwner];
    }
    return self;
}

@end