//
//  Weapon.h
//  tilegame2
//
//  Created by Jeremiah Anderson on 2/6/13.
//
//

#import "EntityNode.h"

@class EntityNode;

@interface WeaponNode : EntityNode

@property (nonatomic, strong) EntityNode* owner;
@property (nonatomic, assign) CGPoint targetPoint;
@property (nonatomic, assign) int speedInPixelsPerSec;
@property (nonatomic, assign) CGFloat strikingRange;
@property (nonatomic, assign) int damage;

-(id)initInLayer:(CoreGameLayer *)layer atSpawnPoint:(CGPoint)spawnPoint;
-(void)collidedWith:(EntityNode*)entityType;
-(NSMutableDictionary *)cacheStateForEvent:(DVEventType)event;

@end
