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

@class HelloWorldLayer;

// Heads Up Display HUD label / stats layer class declaration (put in separate file in future)
@interface HelloWorldHud : CCLayer
{
    HelloWorldLayer* _gameLayer;  // give the HUD a reference back to the HelloWorldLayer
    CCLabelTTF* label;
}

@property (nonatomic, assign) HelloWorldLayer* gameLayer;

-(void) projectileButtonTapped:(id)sender;
-(void) numCollectedChanged:(int) numCollected;

@end


// HelloWorldLayer
@interface HelloWorldLayer : CCLayer <GKAchievementViewControllerDelegate, GKLeaderboardViewControllerDelegate>
{
    CCTMXTiledMap* _tileMap;
    // these layers are part of the _tileMap
    CCTMXLayer* _background;  // background layer is the constant background layer (walls, roads, bushes, etc)
    CCTMXLayer* _meta;  // meta layer is NOT seen by player, just used to specify collidable, collectible tiles
    CCTMXLayer* _foreground;  // foreground layer is seen by player but is modifiable, like collectible items
    CCSprite* _player;
    NSMutableArray* _enemies;
    NSMutableArray* _projectiles;
    
    int numCollected;
    HelloWorldHud* _hud; // keep a pointer to the HUD labels/stats layer
    int _mode;  // game mode variable - shooting or moving
    
    DVAPIWrapper* apiWrapper;
}

@property (nonatomic, retain) CCTMXTiledMap* tileMap;
@property (nonatomic, retain) CCTMXLayer* background;
@property (nonatomic, retain) CCTMXLayer* meta;
@property (nonatomic, retain) CCTMXLayer* foreground;
@property (nonatomic, retain) CCSprite* player;
@property (nonatomic, assign) int numCollected;
@property (nonatomic, retain) HelloWorldHud* hud;
@property (nonatomic, assign) int mode;

// returns a CCScene that contains the HelloWorldLayer as the only child
+(CCScene *) scene;
- (void) setViewpointCenter:(CGPoint) position;
-(CGPoint) tileCoordForPosition:(CGPoint) position;
-(void) setPlayerPosition:(CGPoint) position;
-(void) addEnemyAtX:(int)x y:(int)y;
-(void) enemyMoveFinished:(id)sender;
-(void) animateEnemy:(CCSprite*) enemy;
-(void) win;
-(void) lose;
-(CGPoint) pixelToPoint:(CGPoint) pixelPoint;
-(CGSize) pixelToPointSize:(CGSize) pixelSize;

@end