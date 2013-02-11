//
//  Missile.h
//  tilegame2
//
//  Created by Jeremiah Anderson on 1/24/13.
//
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"

#import "CCSequence+Helper.h"
//#import "ReplayableEvents.h"
#import "WeaponNode.h"

#define kEntityMissileHitPoints 1
#define kEntityMissileSpeedPPS 240
#define kMissileDamage 2

//@class EntityNode;

@interface Missile : WeaponNode <NSCoding>

-(id)initInLayer:(CoreGameLayer *)layer atSpawnPoint:(CGPoint)spawnPoint withTargetPoint:(CGPoint)targetPoint ownedBy:(EntityNode *)owner;
//-(id)initInLayerWithoutCache_AndAnimate:(CoreGameLayer *)layer atSpawnPoint:(CGPoint)spawnPoint withTargetPoint:(CGPoint)targetPoint ownedBy:(EntityNode *)owner afterDelay:(ccTime) delay;
-(id)initInLayerWithoutCache_AndAnimate:(CoreGameLayer *)layer atSpawnPoint:(CGPoint)spawnPoint ownedBy:(EntityNode *)owner withUniqueID:(int)uniqueID afterDelay:(ccTime) delay;
-(void) realExplode;
-(void) kill;
-(void) animateKill:(CGPoint)killPosition;
-(void) animateExplode;
-(void) realUpdate;

//-(id)initInLayer:(CoreGameLayer *)layer atSpawnPoint:(CGPoint)spawnPoint withBehavior:(DVCreatureBehavior)behavior ownedBy:(EntityNode *)player;

@end
