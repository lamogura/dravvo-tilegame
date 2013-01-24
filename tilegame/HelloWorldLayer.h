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

@class HelloWorldLayer;

// Heads Up Display HUD label / stats layer class declaration (put in separate file in future)
@interface HelloWorldHud : CCLayer
{
    HelloWorldLayer* __unsafe_unretained _gameLayer;  // give the HUD a reference back to the HelloWorldLayer
    CCLabelTTF* labelMelonsCount;
    CCLabelTTF* labelKillsCount;
    CCLabelTTF* labelShurikensCount;
    CCLabelTTF* labelMissilesCount;
}

@property (nonatomic, unsafe_unretained) HelloWorldLayer* gameLayer;

-(void) projectileButtonTapped:(id)sender;
-(void) numCollectedChanged:(int) numCollected;
-(void) numKillsChanged:(int) numKills;
-(void) numShurikensChanged:(int) numShurikens;
-(void) numMissilesChanged:(int) numMissiles;

@end


// HelloWorldLayer
@interface HelloWorldLayer : CCLayer <GKAchievementViewControllerDelegate, GKLeaderboardViewControllerDelegate>
{
    CCTMXTiledMap* _tileMap;
    // these layers are part of the _tileMap
    CCTMXLayer* _background;  // background layer is the constant background layer (walls, roads, bushes, etc)
    CCTMXLayer* _meta;  // meta layer is NOT seen by player, just used to specify collidable, collectible tiles
    CCTMXLayer* _foreground;  // foreground layer is seen by player but is modifiable, like collectible items
    CCTMXLayer* _destruction;  // destruction under-layer, for when terrain is devastated
    CCSprite* _player;
//    NSMutableArray* _enemies;
    NSMutableArray* _projectiles;
    NSMutableArray* _missiles;
    NSMutableArray* _bats;
    
    int _numKills;
    int _numCollected;
    HelloWorldHud* _hud; // keep a pointer to the HUD labels/stats layer
    int _mode;  // game mode variable - shooting or moving
    int _numShurikens;
    int _numMissiles;
    BOOL isSwipe;
    BOOL isTouchMoveStarted;
    NSMutableArray* myToucharray;
    
    DVAPIWrapper* apiWrapper;
}

@property (nonatomic, strong) CCTMXTiledMap* tileMap;
@property (nonatomic, strong) CCTMXLayer* background;
@property (nonatomic, strong) CCTMXLayer* meta;
@property (nonatomic, strong) CCTMXLayer* foreground;
@property (nonatomic, strong) CCTMXLayer* destruction;
@property (nonatomic, strong) CCSprite* player;
@property (nonatomic, assign) int numCollected;
@property (nonatomic, assign) int numKills;
@property (nonatomic, assign) int numShurikens;
@property (nonatomic, assign) int numMissiles;
@property (nonatomic, strong) HelloWorldHud* hud;
@property (nonatomic, assign) int mode;
//@property (nonatomic, strong) NSMutableArray* bats;

// returns a CCScene that contains the HelloWorldLayer as the only child
+(CCScene *) scene;
- (void) setViewpointCenter:(CGPoint) position;
-(CGPoint) tileCoordForPosition:(CGPoint) position;
-(void) setPlayerPosition:(CGPoint) position;
//-(void) addEnemyAtX:(int)x y:(int)y;
-(void) projectileMoveFinished:(id) sender;
-(void) enemyMoveFinished:(id)sender;
-(void) missileMoveFinished:(id) sender;
-(void) animateEnemy:(CCSprite*) enemy;
-(void) win;
-(void) lose;
-(void) missileExplodes:(CGPoint) hitLocation;
-(void) missileExplodesFinished:(id) sender;
-(CGPoint) pixelToPoint:(CGPoint) pixelPoint;
-(CGSize) pixelToPointSize:(CGSize) pixelSize;

@end