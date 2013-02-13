//
//  Chicken.h
//  tilegame2
//
//  Created by Jeremiah Anderson on 2/8/13.
//
//


#import <Foundation/Foundation.h>
#import "cocos2d.h"

#import "CCSequence+Helper.h"
//#import "ReplayableEvents.h"
#import "CreatureNode.h"

#define kEntityChickenHitPoints 9999  // can't really kill the chicken
#define kEntityChickenSpeedPPS 100

@interface Chicken : CreatureNode

@property (nonatomic, assign) int speedInPixelsPerSec;
@property (nonatomic, strong) EntityNode* owner;

-(id)initInLayerWithoutCache:(CoreGameLayer *)layer atSpawnPoint:(CGPoint)spawnPoint withBehavior:(DVCreatureBehavior)behavior ownedBy:(EntityNode *)owner;
-(id)initInLayerWithoutCache_AndAnimate:(CoreGameLayer *)layer atSpawnPoint:(CGPoint)spawnPoint withBehavior:(DVCreatureBehavior)behavior ownedBy:(EntityNode *)owner withUniqueID:(int)uniqueID afterDelay:(ccTime) delay;
-(id)initInLayer:(CoreGameLayer *)layer atSpawnPoint:(CGPoint)spawnPoint withBehavior:(DVCreatureBehavior)behavior ownedBy:(EntityNode *)owner;
//-(CCSprite*) removeSpriteAsChildAndReturnIt;

@end
