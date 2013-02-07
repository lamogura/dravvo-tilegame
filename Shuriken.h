//
//  Shuriken.h
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

#define kEntityShurikenHitPoints 1
#define kEntityShurikenSpeedPPS 300
#define kShurikenDamage 2
#define kShurikenRangeInPixels 300  // in pixels

//@class EntityNode;

@interface Shuriken : WeaponNode

-(id)initInLayer:(CoreGameLayer *)layer atSpawnPoint:(CGPoint)spawnPoint withTargetPoint:(CGPoint)targetPoint ownedBy:(EntityNode *)owner;
//-(id)initInLayerWithoutCache_AndAnimate:(CoreGameLayer *)layer atSpawnPoint:(CGPoint)spawnPoint withTargetPoint:(CGPoint)targetPoint ownedBy:(EntityNode *)owner afterDelay:(ccTime) delay;
-(id)initInLayerWithoutCache_AndAnimate:(CoreGameLayer *)layer atSpawnPoint:(CGPoint)spawnPoint ownedBy:(EntityNode *)owner withUniqueID:(int)uniqueID afterDelay:(ccTime) delay;
-(void) kill;
-(void) realUpdate;
-(void) animateKill:(CGPoint)killPosition;

//-(id)initInLayer:(CoreGameLayer *)layer atSpawnPoint:(CGPoint)spawnPoint withBehavior:(DVCreatureBehavior)behavior ownedBy:(EntityNode *)player;

@end
