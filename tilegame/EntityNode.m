//
//  EntityNode.m
//  tilegame
//
//  Created by mogura on 1/26/13.
//
//

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "CCSequence+Helper.h"
#import <GameKit/GameKit.h>
#import "EntityNode.h"
#import "CoreGameLayer.h"

// Entity's include Bat, Missile, Shuriken, Player?
// IN the very least, make sure that all previous time step actions and animations are finished before performing the next time step's actions from main
@implementation EntityNode

@synthesize gameLayer = _gameLayer;
@synthesize sprite = _sprite;
@synthesize uniqueID = _uniqueID;
@synthesize hitPoints = _hitPoints;
@synthesize isAlive = _isAlive;
@synthesize spawnPoint = _spawnPoint;

-(id)initInLayer:(CCNode *)layer atSpawnPoint:(CGPoint)spawnPoint
{
    if (self = [super init]) {
        self->_gameLayer = layer;
        self->_spawnPoint = spawnPoint;
    }
    return self;
}

-(NSMutableDictionary *)cacheStateForEvent:(DVEventType)event
{
    CoreGameLayer* layer = (CoreGameLayer *)self.gameLayer;
    NSMutableDictionary* eventData = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                      [NSNumber numberWithInt:layer.timeStepIndex], kDVEventKey_TimeStepIndex,
                                      self.entityType, kDVEventKey_EntityType,
                                      [NSNumber numberWithInt:self.uniqueID], kDVEventKey_EntityID,
                                      [NSNumber numberWithInt:event], kDVEventKey_EventType,
                                      nil];
    switch (event) {
        case DVEvent_Spawn:
        case DVEvent_Respawn:
        case DVEvent_Move:
            [eventData addEntriesFromDictionary:
             [NSDictionary dictionaryWithObjectsAndKeys:
              [NSNumber numberWithFloat:self.sprite.position.x], kDVEventKey_CoordX,
              [NSNumber numberWithFloat:self.sprite.position.y], kDVEventKey_CoordY,
              nil]];
            break;
            
        case DVEvent_Wound:
            [eventData addEntriesFromDictionary:
             [NSDictionary dictionaryWithObjectsAndKeys:
              [NSNumber numberWithInt:self.hitPoints], kDVEventKey_HPChange,
              nil]];
            break;
            
        case DVEvent_InitStats:
        case DVEvent_Kill:
        default:
            break;
    }
    
    // Now put this dictionary onto the object's NSMuttableArray
    [self.eventHistory addObject:eventData];
    return eventData;
}

// for sampling during real actions, this should be called (callbacked) once every kTimeStepSeconds for later animation on
-(void)sampleCurrentPosition
{
    [self cacheStateForEvent:DVEvent_Move];

    /*
     // generate a "move" event string entry from last point to current point with a time differential of kPlaybackTickLengthSeconds
     NSString* activityEntry = [NSString stringWithFormat:@"%d aniMove %@ %d %d %d",
     myLayer.timeStepIndex, ownerAndEntityID, uniqueIntID, (int)sprite.position.x, (int)sprite.position.y];
     
     [self.historicalEventsList_local addObject:activityEntry];
     DLog(@"sample...%@",activityEntry);
     */
}

-(void)takeDamage:(int)damagePoints
{
    self.hitPoints -= damagePoints;
    [self cacheStateForEvent:DVEvent_Wound];
    
    /*
     NSString* activityEntry = [NSString stringWithFormat:@"%d wound %@ %d %d -1",
     myLayer.timeStepIndex, ownerAndEntityID, uniqueIntID, hpLost];
     //[Bat uniqueIntIDCounter]
     
     [self.historicalEventsList_local addObject:activityEntry];
     DLog(@"wound...%@",activityEntry);
     */
    
    //  There's concurrency problems here so we have to wait for kill to be called from HelloWorldLayer first FIX
    //    if(hitPoints < 1)
    //        [self kill];
}

@end