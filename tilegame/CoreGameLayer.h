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
#import "CCTMXLayerWrapper.h"

// possible initialization methods of CoreGameLayer
typedef enum {
    NewGameAsHost,
    NewGameAsGuest,  // a new game is started with you as the guest: I. Guest Player's initialization, II. playback, III. Guest player's move
    LoadSavedGame,
//    BeginNextTurn,  // start with playback, then player's move
//    Resume,  // Player closed the app before the JSON update could be sent to server - continue from where left off if possible
} CoreGameInitType;

@class CoreGameHudLayer;
@class Player;

#define kCoreGameLayerTag 13 // for pulling out of scene getChildByTag
#define kCoreGameRoundFinishedNotification @"coreGameRoundFinished" // used for notifications
#define kCoreGamePlaybackFinishedNotification @"playbackGameRoundFinished" // used for notifications

// used for saving/loading user defaults
#define kUserDefaultsKey_GameID @"defaultsGameIDKey"
#define kUserDefaultsKey_DeviceToken @"defaultsDeviceTokenKey"

// for NSCoding
#define kCoreGameSavegameKey @"savedGameKey"

#define kCoreGameNSCodingKey_Background @"backgroundTiles"
#define kCoreGameNSCodingKey_Destruction @"destructionTiles"
#define kCoreGameNSCodingKey_Foreground @"foregroundTiles"
#define kCoreGameNSCodingKey_Meta @"metaTiles"
#define kCoreGameNSCodingKey_Shurikens @"shurikens"
#define kCoreGameNSCodingKey_Missles @"missles"
#define kCoreGameNSCodingKey_Player @"player"
#define kCoreGameNSCodingKey_Opponent @"opponent"

// HelloWorldLayer
@interface CoreGameLayer : CCLayer <NSCoding, GKAchievementViewControllerDelegate, GKLeaderboardViewControllerDelegate>
{
    CCTMXTiledMap* _tileMap;
    // these layers are part of the _tileMap
    
    CCTMXLayerWrapper* _background;  // background layer is the constant background layer (walls, roads, bushes, etc)
    CCTMXLayerWrapper* _meta;  // meta layer is NOT seen by player, just used to specify collidable, collectible tiles
    CCTMXLayerWrapper* _foreground;  // foreground layer is seen by player but is modifiable, like collectible items
    CCTMXLayerWrapper* _destruction;  // destruction under-layer, for when terrain is devastated
    
    BOOL _roundHasStarted; // NO touches processed until startRound()
    
    // touches ivars
    BOOL _isSwipe;
    BOOL _didTouchMoveStart;
    NSMutableArray* _touches;

    DVAPIWrapper* _apiWrapper; // api wrapper for server calls
    
    CGPoint aSpawnPoint1;  // SHIT
    CGPoint aSpawnPoint2;  // SHIT
    
    int _eventArrayIndex;
}

+(void) setServerGameData:(DVServerGameData*) gameData; // static storing last gameData update
+(void) changeNumPlaybacksRunningBy:(int) change;

// returns a scene of the coregamelayer + HUD etc
+(CCScene *) sceneNewGameForPlayerRole:(PlayerRole)playerRole;
+(CCScene *) sceneWithGameFromSavedGame:(NSString *)saveGamePath;

-(id) initFromSaveGamePath:(NSString *)path;
-(void) playbackFinished;

@property (nonatomic, strong) CoreGameHudLayer* hud;
@property (nonatomic, assign) int timeStepIndex; // should count up to 10 or 20, to get to a 10 second round
@property (nonatomic, assign) int eventArrayIndex;
@property (nonatomic, strong) Player* player; // always the local player
@property (nonatomic, strong) Player* opponent; // always the local player
@property (nonatomic, strong) NSMutableArray* collidableProjectiles;
@property (nonatomic, strong) NSMutableDictionary* historicalEventsDict;

// change related consts if you ever any of these properties used in KVO
@property (nonatomic, assign) float roundTimer; // time left in current round
#define kDVNumTimerKVO @"roundTimer"

// call back functions
-(void) mainGameLoop:(ccTime)deltaTime;
-(void) sampleCurrentPositions:(ccTime)deltaTime; // scheduled callback

// helpers
-(void) setViewpointCenter:(CGPoint) position;
-(CGPoint) tileCoordForPosition:(CGPoint) position;
-(void) setPlayerPosition:(CGPoint) position; // FIX maybe this shoudl be more flexible
-(CGPoint) pixelToPoint:(CGPoint) pixelPoint;
-(CGSize) pixelToPointSize:(CGSize) pixelSize;
+(void) setTileArray:(uint32_t *)pArray ForLayer:(CCTMXLayer *)pLayer;
-(void) putViewportOnOpponent;

-(void) explosionAt:(CGPoint) hitLocation effectingArea:(CGRect) area infilctingDamage:(int)damage weaponID:(int)weaponID;

// init helpers
-(id) initAsPlayerWithRole:(PlayerRole)pRole; // FIX it wont take my enum for some reason ??
-(void) initSettings;
-(void) initTilemap;
-(void) initAudio;

// lifecycle functions
-(void) saveGameStateToPath:(NSString *)path; //TODO add error handling
-(void) startRound;
-(void) win;
-(void) lose;
-(void) roundFinished;
-(void) playbackEvents:(NSArray *)events;
//-(void) transitionToNextTurn;
-(GameOverStatus) getGameOverStatus;

+(NSString*) saveGamePath;
#if LONELY_DEBUG
+(NSString *) saveGamePathOfLastPlayersTurn;
#endif
@end