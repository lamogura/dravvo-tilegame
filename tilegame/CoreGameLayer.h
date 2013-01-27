//
//  HelloWorldLayer.h
//  tutorial_TileGame
//
//  Created by Jeremiah Anderson on 12/10/12.
//  Copyright __MyCompanyName__ 2012. All rights reserved.
//
// SEE: http://www.raywenderlich.com/1163/how-to-make-a-tile-based-game-with-cocos2d
// Note: 2 class declarations in this file


#import <GameKit/GameKit.h>
#import "cocos2d.h" // When you import this file, you import all the cocos2d classes
#import "DVAPIWrapper.h"
//#import "Entity.h"
#import "Bat.h"
#import "Player.h"
//#import "Opponent.h"
#import "CoreGameHudLayer.h"

@class CoreGameHudLayer;
@class Player;

// HelloWorldLayer
@interface CoreGameLayer : CCLayer <GKAchievementViewControllerDelegate, GKLeaderboardViewControllerDelegate>
{
    CCTMXTiledMap* _tileMap;
    // these layers are part of the _tileMap
    CCTMXLayer* _background;  // background layer is the constant background layer (walls, roads, bushes, etc)
    CCTMXLayer* _meta;  // meta layer is NOT seen by player, just used to specify collidable, collectible tiles
    CCTMXLayer* _foreground;  // foreground layer is seen by player but is modifiable, like collectible items
    CCTMXLayer* _destruction;  // destruction under-layer, for when terrain is devastated
    
    // all existing 
    NSMutableArray* _shurikens;
    NSMutableArray* _missiles;

    // touches ivars
    BOOL _isSwipe;
    BOOL _didTouchMoveStart;
    NSMutableArray* _touches;

    DVAPIWrapper* _apiWrapper; // api wrapper for server calls
}

// returns a CCScene that contains the HelloWorldLayer as the only child
+(CCScene *) scene;

@property (nonatomic, strong) CoreGameHudLayer* hud;
@property (nonatomic, assign) int timeStepIndex; // should count up to 10 or 20, to get to a 10 second round
@property (nonatomic, strong) Player* player; // always the local player
//@property (nonatomic, strong) Player* opponent;

@property (nonatomic, strong) NSMutableDictionary* historicalEventsDict;

// change related consts if you ever any of these properties used in KVO
@property (nonatomic, assign) float roundTimer; // time left in current round
#define kDVNumTimerKVO @"timer"

// call back functions
-(void) mainGameLoop:(ccTime)deltaTime;
-(void) sampleCurrentPositions:(ccTime)deltaTime; // scheduled callback
-(void) enemyPlaybackLoop:(ccTime)deltaTime;

// entity actions finished
-(void) shurikenMoveFinished:(id) sender;
-(void) enemyMoveFinished:(id)sender;
-(void) missileMoveFinished:(id) sender;
-(void) missileExplodesFinished:(id) sender;

// helpers
-(void) setViewpointCenter:(CGPoint) position;
-(CGPoint) tileCoordForPosition:(CGPoint) position;
-(void) setPlayerPosition:(CGPoint) position; // FIX maybe this shoudl be more flexible
-(CGPoint) pixelToPoint:(CGPoint) pixelPoint;
-(CGSize) pixelToPointSize:(CGSize) pixelSize;

// animation helpers
-(void) animateEnemy:(CCSprite*) enemy;
-(void) missileExplodes:(CGPoint) hitLocation;

// lifecycle functions
-(void) startRound;
-(void) win;
-(void) lose;
-(void) roundFinished;
-(void) enemyPlayback;

@end