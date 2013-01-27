//
//  EntityNode.h
//  tilegame
//
//  Created by mogura on 1/26/13.
//

#import <Foundation/Foundation.h>
#import <GameKit/GameKit.h>
#import "CCSequence+Helper.h"
#import "ccnode.h"

//#import "CoreGameLayer.h"

// sampling rate and playback rate
#define kReplayTickLengthSeconds 0.5

// keys for eventHistory dictionary
#define kDVEventKey_TimeStepIndex @"TimeStepIndex"
#define kDVEventKey_EventType @"EventType"
#define kDVEventKey_OwnerID @"OwnerID"
#define kDVEventKey_EntityType @"EntityType"
#define kDVEventKey_EntityID @"EntityID"
#define kDVEventKey_CoordX @"CoordX"
#define kDVEventKey_CoordY @"CoordY"
#define kDVEventKey_HPChange @"HPChange"

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
@interface EntityNode : CCNode

@property (nonatomic, strong) CCNode* gameLayer;
@property (nonatomic, strong) CCSprite* sprite;
@property (nonatomic, assign) int uniqueID;
@property (nonatomic, assign) int hitPoints;
@property (nonatomic, assign) BOOL isAlive;
@property (nonatomic, assign) CGPoint spawnPoint;
@property (nonatomic, strong) NSString* entityType;
@property (nonatomic, copy) NSMutableArray* eventHistory;

// optional
-(id)initInLayer:(CoreGameLayer *)layer atSpawnPoint:(CGPoint)spawnPoint;
-(void)replayEventsAtTimeIndex:(int)index;
-(NSMutableDictionary *)cacheStateForEvent:(DVEventType)event;

// required - will throw an error if not overridden
+(int)nextUniqueID;  // static function for providing unique integer IDs to each new instance of each particular entity kind
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
-(void)replayMoveTo:(CGPoint)targetPoint;  // will animate a historical move over time interval kTimeStepSeconds
-(void)aniExplode:(CGPoint) targetPoint;  // animate it exploding TODO this should move to weapon

-(void)takeActions;

@end