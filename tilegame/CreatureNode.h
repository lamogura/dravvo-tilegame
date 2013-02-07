//
//  CreatureNode.h
//  tilegame
//
//  Created by mogura on 1/26/13.
//
//

#import "EntityNode.h"
//#import "Player.h"

typedef enum {
    DVCreatureBehaviorDefault,        // entity will take its default actions
    DVCreatureBehaviorIdle,           // entity will take no actions
    DVCreatureBehaviorAttackOpponent, // entity will attack opponent
    DVCreatureBehaviorAttackPlayer,   // entity will attack player
    DVCreatureBehaviorRandom,         // entity will take random actions
} DVCreatureBehavior;

@class EntityNode;

@interface CreatureNode : EntityNode <NSCoding>

// NSCoding keys
#define CreatureNodeSpeedInPixelsPerSec @"speedInPixelsPerSec"
#define CreatureNodeBehavior @"behavior"
#define CreatureNodeOwner @"owner"

@property (nonatomic, assign) int speedInPixelsPerSec;
@property (nonatomic, assign) DVCreatureBehavior behavior;

// @property (nonatomic, assign) CGPoint previousPosition;

@property (nonatomic, strong) EntityNode* owner;

-(id)initInLayer:(CoreGameLayer *)layer atSpawnPoint:(CGPoint)spawnPoint withBehavior:(DVCreatureBehavior)behavior ownedBy:(EntityNode *)owner;

@end

