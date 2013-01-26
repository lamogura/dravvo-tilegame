//
//  Player2.h
//  dravvo-tilegame_master
//
//  Created by Jeremiah Anderson on 1/22/13.
//
//  Opponent is NOT an Entity (too unique)

#import <Foundation/Foundation.h>
#import "cocos2d.h"
#import "CoreGameLayer.h"
//#import "Entity.h"
#import "CCSequence+Helper.h"
#import "ChangeableObject.h"

// multiplayer other player object
@interface Opponent : ChangeableObject

@property (nonatomic, retain) CCSprite* opponentSprite;
@property (nonatomic, retain) CoreGameLayer* myLayer;
@property (nonatomic, assign) int hitPoints;
@property (nonatomic, assign) NSString* playerID;
@property (nonatomic, strong) NSMutableArray* playerMinionList;  // player maintains an array of minions

-(id)initWithLayer:(CoreGameLayer*) layer andPlayerID:(NSString*)plyrID andSpawnAt:(CGPoint) spawnPoint;
//-(void)sampleCurrentPosition:(CGPoint) currentPoint;  // don't need this since player should be non-moving during player's turn

// attributes
// CCSprite with MOST RECENT position, hp

// ALL we need to do is animate what has happened, DO NOT actually perform the action as in the main program.
// Changes to the environment that resulted from animations will be passed later in the queue
// For example, for player2 firing a missile

// methods... A player object can:
// loadPreviousActions() // load the actions into a queue via the server API wrapper
// playPreviousActions() // start popping from the queue and flow through a switch statement performing appropriate actions and changes in sequence

// I. Monsters all move to their final destination
// Move all monsters, and wait until all their moves are done before player's actions queue starts
// action, startCoord, finishCoord
// monster3, startCoord, finishCoord (move)
// 

// WHAT monster actions can be done?


// WHAT environment change actions can be done?

// WHAT player actions can be done to the environment?
// playerMove
// playerMissile
// playerShuriken

// action, startCoord, finishCoord
// shuriken, (10,10), (100,100)
//

@end

// overall logic flow:
// 0. player1 starts a multi game on the server with username request (then wait...)
// I. player1 actions and minion actions (realtime, simultaneous)
//  I. A. player1's every move and action is queued
//  I. B. minion's every move and every action in order they occurred (including death positions)
// II. player1 posts actions queue to player2
// III. player2
// II. player2 actions and player2.minion actions (realtime, simultaneous)




