//
//  EntityNode.h
//  tilegame
//
//  Created by mogura on 1/26/13.
//

#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>
//#import "CCSequence+Helper.h"
//#import "CCSequenceHelper.h"
#import "ccnode.h"
#import "cocos2d.h"

//#import "CoreGameLayer.h"

// keys for eventHistory dictionary
#define kDVEventKey_TimeStepIndex @"TimeStepIndex"
#define kDVEventKey_EventType @"EventType"
#define kDVEventKey_OwnerID @"OwnerID"
#define kDVEventKey_EntityType @"EntityType"
#define kDVEventKey_EntityID @"EntityID"
#define kDVEventKey_CoordX @"CoordX"
#define kDVEventKey_CoordY @"CoordY"
#define kDVEventKey_HPChange @"HPChange"

// entityTypes defined in the respective sub-class's constructors
#define kEntityTypePlayer @"player"
#define kEntityTypeBat @"bat"

// possible events
typedef enum {
    DVEvent_Spawn,
    DVEvent_Move,
    DVEvent_Wound,
    DVEvent_Kill,
    DVEvent_Respawn,
    DVEvent_InitStats,
} DVEventType;

@class CoreGameLayer;

// Entity's include Bat, Missile, Shuriken, Player?
// IN the very least, make sure that all previous time step actions and animations are finished before performing the next time step's actions from main
@interface EntityNode : CCNode <NSCoding>

// constant keys for NSCoding
#define EntityNodeUniqueID @"uniqueID"
#define EntityNodeHitPoints @"hitPoints"
#define EntityNodeSpawnPoint @"spawnPoint"
#define EntityNodePosition @"positionPoint"

@property (nonatomic, strong) CCNode* gameLayer;
@property (nonatomic, strong) CCSprite* sprite;
@property (nonatomic, assign) int uniqueID;
@property (nonatomic, assign) int hitPoints;
@property (nonatomic, assign) BOOL isAlive;
@property (nonatomic, assign) CGPoint spawnPoint;
@property (nonatomic, assign) CGPoint lastPoint;
@property (nonatomic, strong) NSString* entityType;
@property (nonatomic, strong) NSMutableArray* actionsToBePlayed;
//@property (nonatomic, copy) NSMutableArray* eventHistory;

+(NSMutableArray*) eventHistory;  // returns the entire event history static getter method
//+(int) numAnimationsPlaying;
//+(void) callbackAnimationsFinished;
+(void) animateDeathForEntityType:(NSString*) theEntityType at:(CGPoint) deathPoint;  // TO DO Takes a position and an EntityType
// optional
-(id)initInLayer:(CoreGameLayer *)layer atSpawnPoint:(CGPoint)spawnPoint;
-(id)initInLayerWithoutCache:(CoreGameLayer *)layer atSpawnPoint:(CGPoint)spawnPoint;
//-(void)replayEventsAtTimeIndex:(int)index;
-(NSMutableDictionary *)cacheStateForEvent:(DVEventType)event;

// required - will throw an error if not overridden
//+(int)nextUniqueID;  // static function for providing unique integer IDs to each new instance of each particular entity kind
-(void)sampleCurrentPosition; 

// State changes like decreasing HP or killing a creature
-(void)takeDamage:(int)damagePoints;
-(void)kill; // possibly animate a death then remove this minion

// List of real actions the entity can do to interact with the environment state changes
-(void)realUpdate;
-(void)realSetBehaviour:(int) newBeahavior;
-(void)realMove:(CGPoint) targetPoint;
-(void)realExplode:(CGPoint) targetPoint;

// List of historical animations that simluate past actions without any environment state changes, for later animation re-play on player2's side
// each minion has it's own list of animations that can be performed on it, such as exploding, moving, attacking,
-(void)animateExplode:(CGPoint) targetPoint;  // animate it exploding TODO this should move to weapon
-(void)animateMove:(CGPoint) targetPoint;  // will animate a historical move over time interval kTimeStepSeconds
-(void)animateTakeDamage:(int)damagePoints;
-(void)animateKill;

-(void)playActionsInSequenceAndCallback_tryEnemyPlayback;  // plays all the actions in sequence FOR EACH entity object

@end