//
//  Weapon.m
//  tilegame2
//
//  Created by Jeremiah Anderson on 2/6/13.
//
//

#import "WeaponNode.h"

@implementation WeaponNode

@synthesize owner = _owner;
@synthesize targetPoint = _targetPoint;
@synthesize speedInPixelsPerSec = _speedInPixelsPerSec;
@synthesize strikingRange = _strikingRange;
@synthesize damage = _damage;


-(id)initInLayer:(CoreGameLayer *)layer atSpawnPoint:(CGPoint)spawnPoint
{
    if(self = [super initInLayer:layer atSpawnPoint:spawnPoint])
    {
        
    }
    return self;
}

-(void)collidedWith:(EntityNode*)entityType
{
    
}

-(NSMutableDictionary *)cacheStateForEvent:(DVEventType)event {
    NSMutableDictionary* eventData = [super cacheStateForEvent:event];
    [eventData addEntriesFromDictionary:[NSDictionary dictionaryWithObjectsAndKeys:
                                         [NSNumber numberWithInt:self.owner.uniqueID], kDVEventKey_OwnerID,
                                         nil]];  // was self.owner.uniqueID + 1
    return eventData;
}


@end
