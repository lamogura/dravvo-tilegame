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



-(void)collidedWith:(EntityNode*)entityType
{
    // TODO: implement
}

-(NSMutableDictionary *)cacheStateForEvent:(DVEventType)event {
    NSMutableDictionary* eventData = [super cacheStateForEvent:event];
    [eventData addEntriesFromDictionary:[NSDictionary dictionaryWithObjectsAndKeys:
                                         [NSNumber numberWithInt:self.owner.uniqueID], kDVEventKey_OwnerID,
                                         nil]];  // was self.owner.uniqueID + 1
    return eventData;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [super encodeWithCoder:coder];

    [coder encodeCGPoint:_targetPoint forKey:WeaponNodeTargetPoint];
    [coder encodeObject:_owner forKey:WeaponNodeOwner];
}

- (id)initWithCoder:(NSCoder *)coder
{
    if (self = [super initWithCoder:coder])
    {
        _targetPoint = [coder decodeCGPointForKey:WeaponNodeTargetPoint];
        _owner = [coder decodeObjectForKey:WeaponNodeOwner];
    }
    return self;
}

@end
