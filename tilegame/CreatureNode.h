//
//  CreatureNode.h
//  tilegame
//
//  Created by mogura on 1/26/13.
//
//

#import "EntityNode.h"
//#import "Player.h"

typedef NS_ENUM(NSInteger, CreatureBehavior) {
    CreatureBehavior_Default,        // entity will take its default actions
    CreatureBehavior_Idle,           // entity will take no actions
    CreatureBehavior_AttackOpponent, // entity will attack opponent
    CreatureBehavior_AttackPlayer,   // entity will attack player
    CreatureBehavior_Random,         // entity will take random actions
};

@class EntityNode;

@interface CreatureNode : EntityNode <NSCoding>

// NSCoding keys
#define CreatureNodeSpeedInPixelsPerSec @"speedInPixelsPerSec"
#define CreatureNodeBehavior @"behavior"
#define CreatureNodeOwner @"owner"

@property (nonatomic, assign) int speedInPixelsPerSec;
@property (nonatomic, assign) CreatureBehavior behavior;

// @property (nonatomic, assign) CGPoint previousPosition;

@property (nonatomic, strong) EntityNode* owner;

-(id)initInLayer:(CoreGameLayer *)layer atSpawnPoint:(CGPoint)spawnPoint withBehavior:(CreatureBehavior)behavior ownedBy:(EntityNode *)owner;

@end

