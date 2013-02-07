
//  HelloWorldLayer.m
//  tutorial_TileGame
//
//  Created by Jeremiah Anderson on 12/10/12.
//  Copyright __MyCompanyName__ 2012. All rights reserved.
//
// SEE: http://www.raywenderlich.com/1163/how-to-make-a-tile-based-game-with-cocos2d

// Import the interfaces
#import "CoreGameLayer.h"

// Needed to obtain the Navigation Controller
#import "AppDelegate.h"
#import "SimpleAudioEngine.h"
#import "GameOverScene.h"
#import "DVMacros.h"
#import "DVConstants.h"
#import "gameConstants.h"
//#import "CCSequence+Helper.h"
#import "CCSequenceHelper.h"

#import "Libs/SBJSON/SBJson.h"

#import "Bat.h"
#import "Player.h"
//#import "Opponent.h"
//#import "RoundFinishedScene.h"
#import "CountdownLayer.h"
#import "LoadingLayer.h"
#import "EntityNode.h"

#pragma mark - CoreGameLayer

static BOOL _isEnemyPlaybackRound = NO;
static int _playerID;
static int _numPlaybacksRunning;
static int numPlaybacksMethodsRunning;
static DVServerGameData* _serverGameData;

@implementation CoreGameLayer

@synthesize hud = _hud;
@synthesize timeStepIndex = _timeStepIndex;
@synthesize eventArrayIndex = _eventArrayIndex;
@synthesize player = _player;
@synthesize opponent = _opponent;
@synthesize historicalEventsDict = _historicalEventsDict;
//@synthesize eventHistory = _eventHistory;

@synthesize roundTimer = _roundTimer;

+(void) setServerGameData:(DVServerGameData*) gameData  // static to store last game data update
{
    if(_serverGameData == nil)
        _serverGameData = [[DVServerGameData alloc] init];
    _serverGameData = gameData;
}

+(void) setPlayerID:(int)setID
{
    _playerID = setID;
}

+(int) playerID
{
    return _playerID;

}

+(void) changeNumPlaybacksRunningBy:(int)change
{
    _numPlaybacksRunning += change;
}

// Helper class method that creates a Scene with the HelloWorldLayer as the only child.
// What calls this class??
+(CCScene *) scene:(DVCoreLayerInitType) initType
{
	CCScene *scene = [CCScene node];
    CoreGameLayer *layer;
    
    if (initType == DVNewGameAsHost)
    {
        layer = [CoreGameLayer node];  // regular init
    }
    else if (initType == DVLoadFromFile)
    {
        layer = [[CoreGameLayer alloc] initFromSavedGameState];
    }
    else
    {
        layer = [[CoreGameLayer alloc] initWithInitType:initType];
    }

    CoreGameHudLayer* hud = [[CoreGameHudLayer alloc] initWithCoreGameLayer:layer];
    
    layer.hud = hud;  // store a member var reference to the hud so we can refer back to it to reset the label strings!
    
 	[scene addChild:layer];
    [scene addChild:hud];

    CountdownLayer* cdlayer = [[CountdownLayer alloc] initWithCountdownFrom:3 AndCallBlockWhenCountdownFinished:^(id status) {
        [layer startRound];
    }];

    [scene addChild:cdlayer];
	return scene;
}
/*
+(CCScene *) scenePlaybackOpponentsTurn
{
	CCScene *scene = [CCScene node];

    // I. get the game status's dict and put it into _historicalEvents (or just read off the dict)
    // II. cycle through the _historicalEvents, spawning, moving, etc by calling various Entity's static methods
    // if the dict key is a bat, send it to a bat
    // if the dict key is a Player, send it to the player

    //     CoreGameLayer *layer = [CoreGameLayer node];
    CoreGameLayer* layer = [[CoreGameLayer alloc] initWithPlayback];
    CoreGameHudLayer* hud = [[CoreGameHudLayer alloc] initWithCoreGameLayer:layer];
    
    layer.hud = hud;  // store a member var reference to the hud so we can refer back to it to reset the label strings!
    
 	[scene addChild:layer];
    [scene addChild:hud];
    
    CountdownLayer* cdlayer = [[CountdownLayer alloc] initWithCountdownFrom:3 AndCallBlockWhenCountdownFinished:^(id status) {
        [layer startRound];
    }];
    
    [scene addChild:cdlayer];
	return scene;
}
 */

#pragma mark - Game Lifecycle

-(id) init
{
	if(self=[super init]) {
        numPlaybacksMethodsRunning = 0;
        // init the wrapper class for the api
        self->_apiWrapper = [[DVAPIWrapper alloc] init];
        // This code isn't reached unless we are the HOST, and therefore HOST playerID = 1, GUEST = 2
        _playerID = 1;  // public static variable of the layer class, only set once when a new game has been started
        
        _timeStepIndex = 0; // step index for caching events
        _numPlaybacksRunning = 0;
//        _eventHistory = [[NSMutableArray alloc] init];
        self.isTouchEnabled = YES;  // set THIS LAYER as touch enabled so user can move character around with callbacks
		_isSwipe = NO; // what does this do?
        _touches = [[NSMutableArray alloc ] init]; // store the touches for missile launching

        _roundHasStarted = NO; // wait for startRound()
        self.roundTimer = (float) kTurnLengthSeconds;
        
        _shurikens = [[NSMutableArray alloc] init];
        _missiles =  [[NSMutableArray alloc] init];

        [self audioInitAndPlay];
        
        // load the TileMap and the tile layers
        _tileMap = [CCTMXTiledMap tiledMapWithTMXFile:@"TileMap.tmx"];
        _background = [_tileMap layerNamed:@"Background"];
        _meta = [_tileMap layerNamed:@"Meta"];
        _foreground = [_tileMap layerNamed:@"Foreground"];
        _destruction = [_tileMap layerNamed:@"Destruction"];
        _meta.visible = NO;

        // set playerID inside the NewGameLayer class, HOST = 1, GUEST = 2, etc
        
        CCTMXObjectGroup* playerSpawnObjects = [_tileMap objectGroupNamed:@"PlayerSpawnPoints"];
        NSAssert(playerSpawnObjects != nil, @"'PlayerSpawnPoints' object group not found");

        NSDictionary* spawnPointsDict = [[NSDictionary alloc] init];
        for(spawnPointsDict in [playerSpawnObjects objects])
        {   // _player has not been instantiated yet, so check [Player nextUniqueID]
            if([[spawnPointsDict valueForKey:@"Owner"] intValue] == _playerID)
            {
                CGPoint playerSpawnPoint = [self pixelToPoint: ccp([[spawnPointsDict valueForKey:@"x"] intValue],[[spawnPointsDict valueForKey:@"y"] intValue])];
                DLog(@"CGPoint:%f,%f",playerSpawnPoint.x,playerSpawnPoint.y);
                
                _player = [[Player alloc] initInLayer:self atSpawnPoint:playerSpawnPoint withUniqueIntID:_playerID withShurikens:kInitShurikens withMissles:kInitMissiles];
            }
        }

        int opponent_ID = _playerID == 1 ? 2 : 1;  // don't need to save this as member var - only for opponent instantiation for enemy target
        // DEBUG for now, spawn opponent as Player 2 (assuming we are host not guest
        for(spawnPointsDict in [playerSpawnObjects objects])
        {   // _player has not been instantiated yet, so check [Player nextUniqueID]
            if([[spawnPointsDict valueForKey:@"Owner"] intValue] == opponent_ID)
            {
                CGPoint playerSpawnPoint = [self pixelToPoint: ccp([[spawnPointsDict valueForKey:@"x"] intValue],[[spawnPointsDict valueForKey:@"y"] intValue])];
                DLog(@"CGPoint:%f,%f",playerSpawnPoint.x,playerSpawnPoint.y);
                
                _opponent = [[Player alloc] initInLayer:self atSpawnPoint:playerSpawnPoint withUniqueIntID:opponent_ID withShurikens:kInitShurikens withMissles:kInitMissiles];
            }
        }
        
        int count = 0;  // SHIT
        
        CCTMXObjectGroup* minionSpawnObjects = [_tileMap objectGroupNamed:@"MinionSpawnPoints"];
        NSAssert(minionSpawnObjects != nil, @"'MinionSpawnPoints' object group not found");
        
        // objects method returns an array of objects (in this case dictionaries) from the ObjectGroup
        for(spawnPointsDict in [minionSpawnObjects objects])
        {
            if([[spawnPointsDict valueForKey:@"Owner"] intValue] == _player.uniqueID)
            {
                count++;  // SHIT
                if(count == 3)  // SHIT
                    aSpawnPoint1 = [self pixelToPoint:ccp([[spawnPointsDict valueForKey:@"x"] intValue],
                                       [[spawnPointsDict valueForKey:@"y"] intValue])];
                if(count == 4) // SHIT
                    aSpawnPoint2 = [self pixelToPoint: ccp([[spawnPointsDict valueForKey:@"x"] intValue],
                                       [[spawnPointsDict valueForKey:@"y"] intValue])];
                DLog(@"Player ID: %d",_player.uniqueID);
                CGPoint enemySpawnPoint = [self pixelToPoint:
                    ccp([[spawnPointsDict valueForKey:@"x"] intValue],
                        [[spawnPointsDict valueForKey:@"y"] intValue])];

                Bat *bat = [[Bat alloc] initInLayer:self
                                       atSpawnPoint:enemySpawnPoint
                                       withBehavior:DVCreatureBehaviorDefault
                                            ownedBy:_player];                
                
//                [eventData addEntriesFromDictionary:
//                 [NSDictionary dictionaryWithObjectsAndKeys:
//                  [NSNumber numberWithInt:self.hitPoints], kDVEventKey_HPChange,
//                  nil]];
                [_player.minions addEntriesFromDictionary:[NSDictionary dictionaryWithObject:bat forKey:[NSNumber numberWithInt:bat.uniqueID]]];
                DLog(@"Bat is owned by player ID: %d",bat.owner.uniqueID);

                //[self.player.minions addObject:bat]; // just in case KVO is used in future
            }
        }
//        DLog(@"Number of bats = %@", [_player.minions ])
        
        // set the view position focused on player
        [self setViewpointCenter:_player.sprite.position];
        [self addChild:_tileMap z:-1];
//        [self startRound];
    }
	return self;
}

-(id) initWithInitType:(DVCoreLayerInitType) initType
{
	if(self=[super init]) {

        // Common initializations to all
        self->_apiWrapper = [[DVAPIWrapper alloc] init];
        [self audioInitAndPlay];
        _shurikens = [[NSMutableArray alloc] init];
        _missiles =  [[NSMutableArray alloc] init];
        _timeStepIndex = 0; // step index for caching events
        _roundHasStarted = NO; // wait for startRound()
        self.roundTimer = (float) kTurnLengthSeconds;


        switch (initType) {
            case DVNewGameAsGuest:  // didn't get here unless DVServerGameData was packed with the opponent's goods
            {
                // Playback enemy turn first
                // Initialize this player's state and begin the usual action
                _playerID = 2;
                // must create the opponent before playback of enemy turn as this is automatic on HOST and GUEST
                // load the TileMap and the tile layers

                _tileMap = [CCTMXTiledMap tiledMapWithTMXFile:@"TileMap.tmx"];
                _background = [_tileMap layerNamed:@"Background"];
                _meta = [_tileMap layerNamed:@"Meta"];
                _foreground = [_tileMap layerNamed:@"Foreground"];
                _destruction = [_tileMap layerNamed:@"Destruction"];
                _meta.visible = NO;
                
                // set playerID inside the NewGameLayer class, HOST = 1, GUEST = 2, etc
                
                CCTMXObjectGroup* playerSpawnObjects = [_tileMap objectGroupNamed:@"PlayerSpawnPoints"];
                NSAssert(playerSpawnObjects != nil, @"'PlayerSpawnPoints' object group not found");
                
                NSDictionary* spawnPointsDict = [[NSDictionary alloc] init];
                for(spawnPointsDict in [playerSpawnObjects objects])
                {   // _player has not been instantiated yet, so check [Player nextUniqueID]
                    if([[spawnPointsDict valueForKey:@"Owner"] intValue] == _playerID)
                    {
                        CGPoint playerSpawnPoint = [self pixelToPoint: ccp([[spawnPointsDict valueForKey:@"x"] intValue],[[spawnPointsDict valueForKey:@"y"] intValue])];
                        DLog(@"CGPoint:%f,%f",playerSpawnPoint.x,playerSpawnPoint.y);
                        
                        _player = [[Player alloc] initInLayer:self atSpawnPoint:playerSpawnPoint withUniqueIntID:_playerID withShurikens:kInitShurikens withMissles:kInitMissiles];
                    }
                }
                
                int opponent_ID = _playerID == 1 ? 2 : 1;  // don't need to save this as member var - only for opponent instantiation for enemy target
                // DEBUG for now, spawn opponent as Player 2 (assuming we are host not guest
                for(spawnPointsDict in [playerSpawnObjects objects])
                {   // _player has not been instantiated yet, so check [Player nextUniqueID]
                    if([[spawnPointsDict valueForKey:@"Owner"] intValue] == opponent_ID)
                    {
                        CGPoint playerSpawnPoint = [self pixelToPoint: ccp([[spawnPointsDict valueForKey:@"x"] intValue],[[spawnPointsDict valueForKey:@"y"] intValue])];
                        DLog(@"CGPoint:%f,%f",playerSpawnPoint.x,playerSpawnPoint.y);
                        
                        _opponent = [[Player alloc] initInLayer:self atSpawnPoint:playerSpawnPoint withUniqueIntID:opponent_ID withShurikens:kInitShurikens withMissles:kInitMissiles];
                    }
                }
                
                CCTMXObjectGroup* minionSpawnObjects = [_tileMap objectGroupNamed:@"MinionSpawnPoints"];
                NSAssert(minionSpawnObjects != nil, @"'MinionSpawnPoints' object group not found");
                
                // objects method returns an array of objects (in this case dictionaries) from the ObjectGroup
                for(spawnPointsDict in [minionSpawnObjects objects])
                {
                    if([[spawnPointsDict valueForKey:@"Owner"] intValue] == _player.uniqueID)
                    {
                        DLog(@"Player ID: %d",_player.uniqueID);
                        CGPoint enemySpawnPoint = [self pixelToPoint:
                                                   ccp([[spawnPointsDict valueForKey:@"x"] intValue],
                                                       [[spawnPointsDict valueForKey:@"y"] intValue])];
                        
                        Bat *bat = [[Bat alloc] initInLayer:self
                                               atSpawnPoint:enemySpawnPoint
                                               withBehavior:DVCreatureBehaviorDefault
                                                    ownedBy:_player];
                        DLog(@"Bat is owned by player ID: %d",bat.owner.uniqueID);
                        
                        [self.player.minions addEntriesFromDictionary:[NSDictionary dictionaryWithObject:bat forKey:[NSNumber numberWithInt:bat.uniqueID]]];
                        //[self.player.minions addObject:bat]; // just in case KVO is used in future
                    }
                }
                // set the view position focused on player
                [self setViewpointCenter:_player.sprite.position];
                [self addChild:_tileMap z:-1];

                // delay here so Player2 can soak in the veiw before enemy playback
                [NSThread sleepForTimeInterval:2];  // seconds?
//                [self enemyPlaybackLoop:0];  // call the opponent round playback method before our turn
                
                [self setViewpointCenter:_player.sprite.position];  // change the view back again to player
                [self addChild:_tileMap z:-1];
                
                self.isTouchEnabled = YES;  // set THIS LAYER as touch enabled so user can move character around with callbacks
                _isSwipe = NO; // what does this do?
                _touches = [[NSMutableArray alloc ] init]; // store the touches for missile launching
            }
                break;
            case DVBeginNextTurn:  // didn't get here unless DVServerGameData was packed with the opponent's goods
            {
                [self reloadGameState];  // reload the current game state before replay and play
                [self setViewpointCenter:_player.sprite.position];
                [self addChild:_tileMap z:-1];

                [NSThread sleepForTimeInterval:2];  // seconds?
//                [self enemyPlaybackLoop:0];  // call the opponent round playback method before our turn
                
                [self setViewpointCenter:_player.sprite.position];  // change the view back again to player
                [self addChild:_tileMap z:-1];

                self.isTouchEnabled = YES;  // set THIS LAYER as touch enabled so user can move character around with callbacks
                _isSwipe = NO; // what does this do?
                _touches = [[NSMutableArray alloc ] init]; // store the touches for missile launching
            }
                break;
            case DVResume:
                // DO STUFF
                break;
            default:
                break;
        }
    }
    return self;
}

+(NSString*) gameStateFilePath
{
    NSString *gameID = [[NSUserDefaults standardUserDefaults] objectForKey:kCurrentGameIDKey];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [NSString stringWithFormat:@"%@/%@.plist", [paths objectAtIndex:0], gameID];
}

-(void) saveGameState //TODO add error handling
{
    NSMutableData *data = [[NSMutableData alloc] init];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    
    [archiver encodeObject:self forKey:CoreGameSavedGameKey];
    [archiver finishEncoding];
    [data writeToFile:[CoreGameLayer gameStateFilePath] atomically:YES];
}

-(id) initFromSavedGameState
{
    // Reload all state variables, including map, player, minion instances and display sprites, etc
    NSString* path = [CoreGameLayer gameStateFilePath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path])
    {
        NSData *codedData = [[NSData alloc] initWithContentsOfFile:path];
        if (codedData != nil)
        {
            NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:codedData];
            self = [unarchiver decodeObjectForKey:CoreGameSavedGameKey];
            [unarchiver finishDecoding];
        }
    }
    else
    {
        ULog(@"Tried to load from file, but no file existed. Using standard init()");
        self = [self init];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
//    [coder encodeInt:*(_destruction.tiles) forKey:CoreGameDestructionTilesKey];
//    [coder encodeInt:*(_foreground.tiles) forKey:CoreGameForegroundTilesKey];
//    [coder encodeInt:*(_meta.tiles) forKey:CoreGameMetaTilesKey];
    [coder encodeObject:self.player forKey:CoreGamePlayerKey];
//    [coder encodeObject:self.opponent forKey:CoreGameOpponentKey];
}

- (id)initWithCoder:(NSCoder *)coder
{
    if (self = [self init])
    {
//        uint32_t intVal;
//        
//        intVal = [coder decodeIntForKey:CoreGameDestructionTilesKey];
//        _destruction.tiles = &(intVal);
//        intVal = [coder decodeIntForKey:CoreGameForegroundTilesKey];
//        _foreground.tiles = &(intVal);
//        intVal = [coder decodeIntForKey:CoreGameMetaTilesKey];
//        _meta.tiles = &(intVal);
        
        self.player = [coder decodeObjectForKey:CoreGamePlayerKey];
        [self addChild:self.player];
//        self.opponent = [coder decodeObjectForKey:CoreGameOpponentKey];
    }
    return self;
}

-(void) audioInitAndPlay
{
    // sound effects pre-load
    [SimpleAudioEngine sharedEngine].backgroundMusicVolume = 0.70;
    [[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"DMMainTheme.m4r"];
    
    [SimpleAudioEngine sharedEngine].effectsVolume = 1.0;
    [[SimpleAudioEngine sharedEngine] preloadEffect:@"DMLifePack.m4r"];
    [[SimpleAudioEngine sharedEngine] preloadEffect:@"hit.caf"];
    [[SimpleAudioEngine sharedEngine] preloadEffect:@"move.caf"];
    [[SimpleAudioEngine sharedEngine] preloadEffect:@"missileSound.m4a"];
    [[SimpleAudioEngine sharedEngine] preloadEffect:@"missileExplode.m4a"];
    [[SimpleAudioEngine sharedEngine] preloadEffect:@"shurikenSound.m4a"];
    [[SimpleAudioEngine sharedEngine] preloadEffect:@"DMPlayerDies.m4r"];
    [[SimpleAudioEngine sharedEngine] preloadEffect:@"DMZombie.m4r"];
    [[SimpleAudioEngine sharedEngine] preloadEffect:@"DMZombiePain.m4r"];
}


-(void) startRound {
    _roundHasStarted = YES; // turn on touch processing
    
    // turn on all the event loops
    [self schedule:@selector(testCollisions:)];
    [self schedule:@selector(mainGameLoop:) interval:kTickLengthSeconds];
    [self schedule:@selector(sampleCurrentPositions:) interval:kReplayTickLengthSeconds];
//    [self schedule:@selector(roundFinished) interval:0 repeat:0 delay:12];
}


-(void) roundFinished
{
    [self saveGameState];
    
    isTouchEnabled_ = NO;
    // temp only - replace with server game data object
    eventsArray = [NSMutableArray arrayWithArray:[EntityNode eventHistory]]; // NSMutableArray*
    DLog(@"eventsArray count = %d",[eventsArray count]);

    _timeStepIndex = 0;
//    [self schedule:@selector(enemyPlaybackLoop) interval:kReplayTickLengthSeconds repeat:10 delay:0];
//    [self repeatMe];
//    [self schedule:@selector(enemyPlaybackLoop:)];
    //[self enemyPlaybackLoop:0];  // DEBUG only for testing
//    [self schedule:@selector(enemyPlaybackLoop:) interval:(kReplayTickLengthSeconds) repeat:20 delay:0];
    [self enemyPlaybackLoop:0];
    /*
    // transition to a waiting for opponent scene, ideally displaying current stats (maybe keep HUD up)
    GameOverScene *gameOverScene = [GameOverScene node];
    [gameOverScene.layer.label setString:@"Round Finished!"];
    [[CCDirector sharedDirector] replaceScene:gameOverScene];
     */
}

- (void) win {
    GameOverScene *gameOverScene = [GameOverScene node];
    [gameOverScene.layer.label setString:@"You Win!"];
    [[CCDirector sharedDirector] replaceScene:gameOverScene];
}

- (void) lose {
    // delete the player, re-init and re-spawn him back at the beginning,
    // then idle him there until turn is finished (no moving or attacking allowed)
    
    [_player takeDamage:2];
    [_player kill];
    
    // [self scheduleOnce:@selector(roundFinished) delay:3.0];
    
    //    GameOverScene *gameOverScene = [GameOverScene node];
    //    [gameOverScene.layer.label setString:@"You Lose!"];
    //    [[CCDirector sharedDirector] replaceScene:gameOverScene];
}

#pragma mark - Callbacks
-(void) mainGameLoop:(ccTime)deltaTime
{
    // update the minions
//    for (Bat *theMinion in _player.minions) {
//        [theMinion realUpdate];
    //DLog(@"mainGameLoop start");
    for (EntityNode *minion in [_player.minions allValues])
        [minion realUpdate];
        
    //DLog(@"mainGameLoop finish");
}

// at the end of the tick, we find out where the sprites travelled to and then we insert the "move" activity to the SECOND index
// of each local activityReport list, so as not to precede a possible "spawn" activity and therefore have a re-play issue
-(void) sampleCurrentPositions:(ccTime)deltaTime
{
    // get the reports before incrementing _timeStepIndex
    
    // sample player
    DLog(@"sampleCurrentPositions:() at _timeStepIndex = %d", _timeStepIndex);
    [_player sampleCurrentPosition];
    
    // sample minions
    for (EntityNode *minion in [_player.minions allValues])
        [minion sampleCurrentPosition];

    // TODO sample the other entities
    
    self.roundTimer -= kReplayTickLengthSeconds;

    _timeStepIndex++;
    // unschedule us and mainGameLoop
    
    if((float)_timeStepIndex * kReplayTickLengthSeconds >= (kTurnLengthSeconds))
    {
        [self unschedule:@selector(sampleCurrentPositions:)];
        [self unschedule:@selector(mainGameLoop:)];
        [self unschedule:@selector(testCollisions:)];
        // wait a couple seconds
//        sleep(2);
        [self roundFinished];  // try a [self scheduleOnce:@selector(enemyPlaybackLoop)]; instead
 
    }
}

-(void) tryEnemyPlayback
{
    _numPlaybacksRunning--;
    if(_numPlaybacksRunning == 0)
        [self scheduleOnce:@selector(enemyPlaybackLoop:) delay:0];
}


-(void) enemyPlaybackLoop:(ccTime)deltaTime//:(int)eventArrayIndex
{
    //NSMutableArray* bullshit = [[NSMutableArray alloc] init];
    @synchronized(_player)
    {

    DLog(@"_eventArrayIndex = %d", _eventArrayIndex);
    DLog(@"[eventsArray count] = %d", [eventsArray count]);
    DLog(@"_timeStepIndex = %d", _timeStepIndex);
        
    [_player.actionsToBePlayed removeAllObjects];
    [_opponent.actionsToBePlayed removeAllObjects];
    for (EntityNode *minion in [_player.minions allValues])  // EntityNode
        [minion.actionsToBePlayed removeAllObjects];
    for (EntityNode *minion in [_opponent.minions allValues])
        [minion.actionsToBePlayed removeAllObjects];

        
    numPlaybacksMethodsRunning++;
    DLog(@"numPlaybacksMethodsRunning = %d", numPlaybacksMethodsRunning);
    /*
    DLog(@"deltaTime = %f",deltaTime);
    if(deltaTime < kReplayTickLengthSeconds)
    {
        DLog(@"Sleeping for %f seconds...",(kReplayTickLengthSeconds - deltaTime));
        [NSThread sleepForTimeInterval:(kReplayTickLengthSeconds - deltaTime)];  // seconds?
    }
     */
//    NSDate* start = [NSDate dateWithTimeIntervalSince1970:0];
    
    DLog(@"_player.sprite.position = %f, %f", _player.sprite.position.x, _player.sprite.position.y);
    
//    double startTime = CACurrentMediaTime();  // init time to now

    DLog(@"[[EntityNode eventHistory] count] = %d",[[EntityNode eventHistory] count]);
    
    // DEBUG - for testing playback, hard-code the _serverGameData.lastUpdates

    // REPLACE ALL eventsArray with _serverGameData.lastUpdates after implementing server stuff
    
//    NSDictionary* stuffDict = [eventsArray objectAtIndex:0];
    
    DLog(@"MADE IT");

    // THIS is where the magic happens - use the static make calls to all the dictionary event objects in _serverGameData
    
    // FIX for multiplayer, need a function to have previously filled all the local arrays with the needed goods
    // loop through the player and each player's minionsList, calling
     
    // cycle through the array, passing the commands goods to Entity (EXCEPT the spawn calls which will be done locally to ensure
    // they are instantiated before an action is called on them)
    
    // start with the [EntityNode eventHistory] should look identical to _serverGameData
 /*
    NSMutableDictionary* eventData = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                      [NSNumber numberWithInt:layer.timeStepIndex], kDVEventKey_TimeStepIndex,
                                      self.entityType, kDVEventKey_EntityType,
                                      [NSNumber numberWithInt:self.uniqueID], kDVEventKey_EntityID,
                                      [NSNumber numberWithInt:event], kDVEventKey_EventType,
                                      nil];
 */
    // pull all for key kDVEventKey_TimeStepIndex == _timeStepIndex
/*
    typedef enum {
        DVEvent_Spawn,
        DVEvent_Move,
        DVEvent_Wound,
        DVEvent_Kill,
        DVEvent_Respawn,
        DVEvent_InitStats,
    } DVEventType;
*/
    
    // All event types but wounded:
    //  kDVEventKey_TimeStepIndex, kDVEventKey_EventType, kDVEventKey_OwnerID, kDVEventKey_EntityType, kDVEventKey_EntityID, kDVEventKey_CoordX, kDVEventKey_CoordY
    // "wounded" event type only:
    //  kDVEventKey_TimeStepIndex, kDVEventKey_EventType, kDVEventKey_OwnerID, kDVEventKey_EntityType, kDVEventKey_EntityID, kDVEventKey_HPChange
    
    
    NSDictionary* event; // = [[NSMutableArray alloc] init];  // just setting pointer
//    if([eventsArray objectAtIndex:0])
//        DLog(@"");
//    event = (NSMutableDictionary*)[eventsArray objectAtIndex:eventArrayIndex];

    if(_eventArrayIndex >= [eventsArray count])
    {
        // DEBUG temporary
        GameOverScene *gameOverScene = [GameOverScene node];
        [gameOverScene.layer.label setString:@"Round Finished!"];
        [[CCDirector sharedDirector] replaceScene:gameOverScene];
    }
        
    event = (NSDictionary*) [eventsArray objectAtIndex:_eventArrayIndex];

//    DLog(@"MADE IT 1");

    if(event == nil)
    {
        // DEBUG temporary
        GameOverScene *gameOverScene = [GameOverScene node];
        [gameOverScene.layer.label setString:@"Round Finished!"];
        [[CCDirector sharedDirector] replaceScene:gameOverScene];
    }
//    DLog(@"MADE IT 2");

//    while((NSNumber*)[event objectForKey:kDVEventKey_TimeStepIndex] == [NSNumber numberWithInt:_timeStepIndex])
//        if(![(NSNumber*)[event objectForKey:kDVEventKey_TimeStepIndex] isEqualToNumber:[NSNumber numberWithInt:_timeStepIndex]])
    while([(NSNumber*)[event objectForKey:kDVEventKey_TimeStepIndex] isEqualToNumber:[NSNumber numberWithInt:_timeStepIndex]])
    {
        DLog(@"MADE IT 3");

        // pull out the key values
        int ownerID = [(NSNumber*) [event objectForKey:kDVEventKey_OwnerID] intValue];  // int
        DVEventType eventType = [(NSNumber*) [event objectForKey:kDVEventKey_EventType] intValue];  // DVEventType
        NSString* entityType = (NSString*) [event objectForKey:kDVEventKey_EntityType];  // FIX: need to change this to an enum of entityType
        int uniqueID = [(NSNumber*) [event objectForKey:kDVEventKey_EntityID] intValue]; // int
        Player *thePlayer;
        if([entityType isEqualToString:kEntityTypePlayer])
        {
            DLog(@"thePlayer being assigned now");
            if(uniqueID == _player.uniqueID)
            {
                thePlayer = _player;
                DLog(@"thePlayer = _player");
                DLog(@"thePlayer.uniqueID = %d", thePlayer.uniqueID);
                DLog(@"_player.uniqueID = %d", _player.uniqueID);
                if([thePlayer isEqual:_player])
                {
                    DLog(@"[thePlayer isEqual:_player] = TRUE");
                }
                else
                {
                    DLog(@"[thePlayer isEqual:_player] FALSE");
                }

            }
            else
            {
                thePlayer = _opponent;
                DLog(@"thePlayer = _opponent");
                DLog(@"thePlayer.uniqueID = %d", thePlayer.uniqueID);
                DLog(@"_opponent.uniqueID = %d", _opponent.uniqueID);
            }
        }
        int xCoord, yCoord, hpChange;
        
        // sanity check DEBUG test
                
        switch (eventType) {
            case DVEvent_Spawn: // spawn
            {
                DLog(@"DVEvent_Spawn found!");
            }
                break;
            case DVEvent_Wound:  // wound
            {
                DLog(@"wound found!");
            }
                break;
            case DVEvent_Move:  // move
            {
                DLog(@"DVEvent_Move found!");
            }
                break;
            case DVEvent_Kill:  // kill
            {
                DLog(@"kill found!");
            }
                break;
            default:
                DLog(@"default!");
                break;
        }
        // finish sanity check
        
        if(eventType == DVEvent_Wound)
            hpChange = [(NSNumber*)[event objectForKey:kDVEventKey_HPChange] intValue];
        else
        {
            xCoord = [(NSNumber*) [event objectForKey:kDVEventKey_CoordX] intValue];
            yCoord = [(NSNumber*) [event objectForKey:kDVEventKey_CoordY] intValue];
        }
        
        DLog(@"ownerID %d, eventType %d, entityType %@, uniqueID %d, xCoord %d, yCoord %d",ownerID, eventType, entityType, uniqueID, xCoord, yCoord);

        DLog(@"MADE IT 4");

        if([entityType isEqualToString:kEntityTypePlayer]) // case 1: action to be performed on the thePlayer (_opponent or _player)
        {
            
            switch (eventType) {
                case DVEvent_Wound:
                    [thePlayer animateTakeDamage:hpChange];
                    break;
                case DVEvent_Move:
                {
                    DLog("cacheing move for _player to point: %d, %d",xCoord, yCoord);
                    [thePlayer animateMove:ccp(xCoord, yCoord)];
                    break;
                }
                case DVEvent_Kill:  // This is NOT a real kill as it would be for minions; the Player remains instantiated, just respawns, re-inits, etc
                    [thePlayer animateKill];  // this call takes care of everything, sounds, respawn, re-init
                    // for now, animateKill also takes care of DVEvent_InitStats and DVEvent_Respawn, which are no longer cached anyway
                    break;
                default:
                    DLog(@"FUCK got a weird eventType in enemyPlaybackLoop's switch");
                    break;
            }

            /*
            if([thePlayer isEqual:_player])  // case: _player
            {
                switch (eventType) {
                    case DVEvent_Wound:
                        [_player animateTakeDamage:hpChange];
                        break;
                    case DVEvent_Move:
                    {
                        DLog("cacheing move for _player to point: %d, %d",xCoord, yCoord);
                        [_player animateMove:ccp(xCoord, yCoord)];
                        break;
                    }
                    case DVEvent_Kill:  // This is NOT a real kill as it would be for minions; the Player remains instantiated, just respawns, re-inits, etc
                        [_player animateKill];  // this call takes care of everything, sounds, respawn, re-init
                        // for now, animateKill also takes care of DVEvent_InitStats and DVEvent_Respawn, which are no longer cached anyway
                        break;
                    default:
                        DLog(@"FUCK got a weird eventType in enemyPlaybackLoop's switch");
                        break;
                }
                //case DVEvent_InitStats:  // only exists for actions on players, not minions
                //case DVEvent_Respawn:  // regenerate in Player, handled in DVEvent_Kill
            }
            else  // case: _opponent
            {
                switch (eventType) {
                    case DVEvent_Wound:
                        [_opponent animateTakeDamage:hpChange];
                        break;
                    case DVEvent_Move:
                    {
                        DLog("cacheing move for _opponent to point: %d, %d",xCoord, yCoord);
                        [_opponent animateMove:ccp(xCoord, yCoord)];
                        break;
                    }
                    case DVEvent_Kill:  // This is NOT a real kill as it would be for minions; the Player remains instantiated, just respawns, re-inits, etc
                        [_opponent animateKill];  // this call takes care of everything, sounds, respawn, re-init
                        // for now, animateKill also takes care of DVEvent_InitStats and DVEvent_Respawn, which are no longer cached anyway
                        break;
                    default:
                        DLog(@"FUCK got a weird eventType in enemyPlaybackLoop's switch");
                        break;
                }
                //case DVEvent_InitStats:  // only exists for actions on players, not minions
                //case DVEvent_Respawn:  // regenerate in Player, handled in DVEvent_Kill
            }
             */
            
            _eventArrayIndex++;
            if(_eventArrayIndex >= [eventsArray count])
            {
                // DEBUG temporary
                GameOverScene *gameOverScene = [GameOverScene node];
                [gameOverScene.layer.label setString:@"Round Finished!"];
                [[CCDirector sharedDirector] replaceScene:gameOverScene];       
            }
            event = (NSDictionary*) [eventsArray objectAtIndex:_eventArrayIndex];
            continue;
        }
        else  // case 2: action goes to a player's minion
        {
            DLog("A Player's minions case");
            // if this is a minion spawn, must instantiate and add to the minions list with appropriate uniqueID
            if(eventType == DVEvent_Spawn)
            {
                /*
                // NOTE: using *WithoutCache init method, so this spawn isn't logged again on the other player's device
                Bat *bat = [[Bat alloc] initInLayerWithoutCache:self
                                       atSpawnPoint:ccp((int)xCoord, (int)yCoord)
                                       withBehavior:DVCreatureBehaviorDefault
                                            ownedBy:thePlayer];
                [thePlayer.minions addEntriesFromDictionary:[NSDictionary dictionaryWithObject:bat forKey:[NSNumber numberWithInt:bat.uniqueID]]];
                 */
               // increment and loop
                _eventArrayIndex++;
                if(_eventArrayIndex >= [eventsArray count])
                {
                    // DEBUG temporary
                    GameOverScene *gameOverScene = [GameOverScene node];
                    [gameOverScene.layer.label setString:@"Round Finished!"];
                    [[CCDirector sharedDirector] replaceScene:gameOverScene];
                }
                event = (NSDictionary*) [eventsArray objectAtIndex:_eventArrayIndex];
                continue;
               
            }
                        
//            EntityNode* theEntity = (EntityNode*)[thePlayer.minions objectForKey:[NSNumber numberWithInt:uniqueID]];
            /*
            EntityNode* theEntity = [EntityNode alloc];
            if([thePlayer isEqual:_player])  // case: _player
                theEntity = (EntityNode*)[_player.minions objectForKey:[NSNumber numberWithInt:uniqueID]];  // ?? CHECK
            else
                theEntity = (EntityNode*)[_opponent.minions objectForKey:[NSNumber numberWithInt:uniqueID]];  // ?? CHECK
             */
            

//            DLog(@"[thePlayer.minions count] = %d",[thePlayer.minions count]);
//            DLog(@"[_player.minions count] = %d",[_player.minions count]);
//            if([thePlayer isEqual:_player])  // case: _player
            if(ownerID == _player.uniqueID)
            {
                DLog(@"[_player.minions count] = %d",[_player.minions count]);
                DLog(@"_player's bats");
                switch (eventType) {
                    case DVEvent_Wound:
                        [((EntityNode*)[_player.minions objectForKey:[NSNumber numberWithInt:uniqueID]]) animateTakeDamage:hpChange];
                        break;
                    case DVEvent_Move:
                    {
                        DLog(@"_player's Bat is moving");
                        [((EntityNode*)[_player.minions objectForKey:[NSNumber numberWithInt:uniqueID]]) animateMove:ccp(xCoord, yCoord)];
                        DLog(@"Bat is done moving");
                    }
                        break;
                    case DVEvent_Kill:
                    {
                        [EntityNode animateDeathForEntityType:entityType at:((Bat*)[_player.minions objectForKey:[NSNumber numberWithInt:uniqueID]]).sprite.position]; // TO DO implement the static call for each entityType
                        [((EntityNode*)[_player.minions objectForKey:[NSNumber numberWithInt:uniqueID]]) animateKill];
//                    [self.player.minions removeObjectForKey:[NSNumber numberWithInt:uniqueID]];
                        [_player.minions removeObjectForKey:[NSNumber numberWithInt:uniqueID]];  // ?? CHECK
                    }
                        break;
                    default:
                        DLog(@"FUCK got a weird eventType in enemyPlaybackLoop's switch");
                        break;
                }
            }
            else if(ownerID == _opponent.uniqueID)  // case: _opponent
            {
                DLog(@"_opponent's bats");
                switch (eventType) {
                    case DVEvent_Wound:
                        [((EntityNode*)[_opponent.minions objectForKey:[NSNumber numberWithInt:uniqueID]]) animateTakeDamage:(int)hpChange];
                        break;
                    case DVEvent_Move:
                    {
                        DLog(@"_opponent's Bat is moving");
                        [((EntityNode*)[_opponent.minions objectForKey:[NSNumber numberWithInt:uniqueID]]) animateMove:ccp((int)xCoord, (int)yCoord)];
                        DLog(@"_opponent's Bat is finished moving");
                    }
                        break;
                    case DVEvent_Kill:
                    {
                        [EntityNode animateDeathForEntityType:entityType at:((Bat*)[_opponent.minions objectForKey:[NSNumber numberWithInt:uniqueID]]).sprite.position]; // TO DO implement the static call for each entityType
                        [((EntityNode*)[_opponent.minions objectForKey:[NSNumber numberWithInt:uniqueID]]) animateKill];
                        //                    [self.player.minions removeObjectForKey:[NSNumber numberWithInt:uniqueID]];
                        [_opponent.minions removeObjectForKey:[NSNumber numberWithInt:uniqueID]];  // ?? CHECK
                    }
                        break;
                    default:
                        DLog(@"FUCK got a weird eventType in enemyPlaybackLoop's switch");
                        break;
                }
            }
            else
                DLog(@"BALLS!");
        
        }
        
        // this won't work! (last animations don't get played)
        _eventArrayIndex++;
        DLog(@"POOP _eventArrayIndex = %d", _eventArrayIndex);
        if(_eventArrayIndex >= [eventsArray count])
        {
            [self transitionToNextTurn];
            DLog(@"_eventArrayIndex >= [eventsArray count] was true");
            // DEBUG temporary
            GameOverScene *gameOverScene = [GameOverScene node];
            [gameOverScene.layer.label setString:@"Round Finished!"];
            [[CCDirector sharedDirector] replaceScene:gameOverScene];
            break;
        }
        event = (NSDictionary*) [eventsArray objectAtIndex:_eventArrayIndex];
        continue;
    }
/*
    if(![(NSNumber*)[event objectForKey:kDVEventKey_TimeStepIndex] isEqualToNumber:[NSNumber numberWithInt:_timeStepIndex]])
    {
        DLog(@"NSNUMBER event key != _timeStepIndex... %@ != %@",(NSNumber*)[event objectForKey:kDVEventKey_TimeStepIndex] ,[NSNumber numberWithInt:_timeStepIndex])
        if(!(((int)(NSNumber*)[event objectForKey:kDVEventKey_TimeStepIndex]) == ((int)[NSNumber numberWithInt:_timeStepIndex])))
        {
            DLog(@"INT event key != _timeStepIndex... %@ != %@",(NSNumber*)[event objectForKey:kDVEventKey_TimeStepIndex] ,[NSNumber numberWithInt:_timeStepIndex]);
        }
        else
        {
            DLog(@"INT event key == _timeStepIndex... %@ != %@",(NSNumber*)[event objectForKey:kDVEventKey_TimeStepIndex] ,[NSNumber numberWithInt:_timeStepIndex]);
        }
    }
 */

    DLog(@"Playing animations");

    // Now start actually playing all the actions in sequence for each
    DLog(@"FINAL [_player._actionsToBePlayed count] = %d",[_player.actionsToBePlayed count]);

    DLog(@"_player playActionsInSequence");
    DLog(@"_numPlaybacksRunning before increment = %d", _numPlaybacksRunning)

    _numPlaybacksRunning += 2;  // _player, _opponent actions
    _numPlaybacksRunning += [_player.minions count];
    _numPlaybacksRunning += [_opponent.minions count];

    DLog(@"_numPlaybacksRunning after increment = %d", _numPlaybacksRunning)
//    DLog(@"_numPlaybacksRunning = %d",_numPlaybacksRunning);
    [_player playActionsInSequenceAndCallback_tryEnemyPlayback];
    DLog(@"_opponent playActionsInSequence");
    [_opponent playActionsInSequenceAndCallback_tryEnemyPlayback];
    int counter = 0;
    for (EntityNode *minion in [_player.minions allValues])  // EntityNode
    {
        counter++;
        DLog(@"_player.minion[%d] playActionsInSequence",counter);
        [minion playActionsInSequenceAndCallback_tryEnemyPlayback];
    }
    counter = 0;
        
    for (EntityNode *minion in [_opponent.minions allValues])
    {
        counter++;
        DLog(@"_opponent.minion[%d] playActionsInSequence",counter);
        [minion playActionsInSequenceAndCallback_tryEnemyPlayback];
    }
    
//    if(([_player.actionsToBePlayed count] != 0) && ([_opponent.actionsToBePlayed count] != 0))
        
    
//// The problem
//    for (Bat *minion in [_player.minions allValues])
//    {
//        [minion.actionsToBePlayed count];
//    }
////
    
    // stall until kReplayTickLengthSeconds has passed before animating the next tick of actions
/*
    if(startTime - CACurrentMediaTime() < (float) kReplayTickLengthSeconds)
    {
//        [NSThread sleepForTimeInterval:(CACurrentMediaTime() - startTime)];  // seconds?
        sleep(CACurrentMediaTime() - startTime);
        DLog(@"Sleeping for %f seconds",(CACurrentMediaTime() - startTime));
    }
*/

//    NSDate* finish = [NSDate dateWithTimeIntervalSince1970:0];
/*  ///  GOOD STUFF  ///
    float passedTime = [[NSDate dateWithTimeIntervalSince1970:0] timeIntervalSinceDate:start];
    float theDelay = passedTime < kReplayTickLengthSeconds ? (kReplayTickLengthSeconds - passedTime) : 0;
    DLog(@"Schedule enemyPlaybackLoop delay = %f seconds...", theDelay);
    [self scheduleOnce:@selector(enemyPlaybackLoop) delay:(theDelay)];
*/
    
//    [self schedule:@selector(enemyPlaybackLoop)];// interval:kReplayTickLengthSeconds repeat:10 delay:0];
/*
    if(_timeStepIndex * kReplayTickLengthSeconds < (float)(kTurnLengthSeconds))
        [self enemyPlaybackLoop:eventArrayIndex];  // next time step
*/
    _timeStepIndex++;

    if(_timeStepIndex * kReplayTickLengthSeconds >= (kTurnLengthSeconds))
    {
//        [self unschedule:@selector(enemyPlaybackLoop)];
        //[NSThread sleepForTimeInterval:(CACurrentMediaTime() - startTime)];  // seconds?

        // DEBUG temporary
        GameOverScene *gameOverScene = [GameOverScene node];
        [gameOverScene.layer.label setString:@"Round Finished!"];
        [[CCDirector sharedDirector] replaceScene:gameOverScene];

        DLog(@"Finished 10 seconds of enemy turn playback");
    }
    
    numPlaybacksMethodsRunning--;
    DLog(@"numPlaybacksMethodsRunning = %d", numPlaybacksMethodsRunning);
    }
    /*
    BOOL isStuffRunning = YES;
    while(isStuffRunning)
    {
        if([_player.actionsToBePlayed count] > 0)
            isStuffRunning = YES;
        else if([_opponent.actionsToBePlayed count] > 0)
            isStuffRunning = YES;
        else
        {
            int count = 0;
            for (EntityNode *minion in [_player.minions allValues])  // EntityNode
            {
                if([minion.actionsToBePlayed count] > 0)
                {
                    isStuffRunning = YES;
                    break;
                }
                count++;
                if(count == [_player.minions count])
                    isStuffRunning = NO;
            }
        }
        DLog(@"Sleeping... 0.10 secs..");

        if(isStuffRunning)
            [NSThread sleepForTimeInterval:(0.10)];  // seconds?
    }
    
    [self enemyPlaybackLoop:0.51];
    [self scheduleOnce:@selector(repeatMe) delay:0];
*/
    
//    [self repeatMe];
    
/*
    NSMutableArray *minionsToDelete = [[NSMutableArray alloc] init];
    for(Bat *theMinion in player.playerMinionList)
    {
        [theMinion performHistoryAtTimeStepIndex: _timeStepIndex];
        if(theMinion == nil)
            [targetsToDelete addObject:theMinion];
    }
    

    // if the minion was just killed, delete it from the player list
    for (Bat *theMinion in player.playerMinionList) {
        if(theMinion == nil)

        [[SimpleAudioEngine sharedEngine] playEffect:@"DMZombiePain.m4r"];
        // _numKills += 1; // only in case of oppononet's minions
        // [_hud numKillsChanged:_numKills];
        [player.playerMinionList removeObject:theMinion];
        }
    }
*/
    // normally would put opponent here, then player next
//    [opponent performHistory: atTimeStepIndex: _timeStepIndex]; // instantiate opponent in layer's init

    // sample player
//    [player performHistoryAtTimeStepIndex: atTimeStepIndex: _timeStepIndex];

//    _timeStepIndex++;
}

-(void) transitionToNextTurn
{
    GameOverScene *gameOverScene = [GameOverScene node];
    [gameOverScene.layer.label setString:@"Round Finished!"];
    [[CCDirector sharedDirector] replaceScene:gameOverScene];

}

-(void) testCollisions:(ccTime) dt
{
    // First, see if lose condition is met locally
    // itterate over the enemies to see if any of them are in contact with player (dead)
    for (Bat *target in [_player.minions allValues]) {
        CGRect targetRect = target.sprite.boundingBox; //CGRectMake(
        //           target.position.x - (target.contentSize.width/2),
        //           target.position.y - (target.contentSize.height/2),
        //           target.contentSize.width,
        //           target.contentSize.height );
        
        if (CGRectContainsPoint(targetRect, _player.sprite.position)) {
            [self lose];
        }
    }
    
    // shurikens hitting enemies?
    NSMutableArray* shurikensToDelete = [[NSMutableArray alloc] init];
    
    for (CCSprite *shuriken in _shurikens) {
        
        NSMutableArray *targetsToDelete = [[NSMutableArray alloc] init];
        
        // iterate through enemies, see if any intersect with current projectile
        for (Bat *target in [_player.minions allValues]) {
            // enemy down!
            if(CGRectIntersectsRect(shuriken.boundingBox, target.sprite.boundingBox))
            {
                [target takeDamage:1];
                //                self.player.numKills += 1;
                //                [_hud numKillsChanged:_numKills];
                [targetsToDelete addObject:target];
                //                [[SimpleAudioEngine sharedEngine] playEffect:@"juliaRoar.m4a"];
            }
        }
        
        // delete all hit enemies
        for (Bat *target in targetsToDelete) {
            if(target.hitPoints < 1)
            {
                [[SimpleAudioEngine sharedEngine] playEffect:@"DMZombie.m4r"];
                
                [target kill];
                self.player.numKills += 1;
                //                [_hud numKillsChanged:_numKills];
                    //[self.player.minions removeObject:target];
                [self.player.minions removeObjectForKey:[NSNumber numberWithInt:target.uniqueID]];
                // [self removeChild:target cleanup:YES]; // child removes itself on [target kill]
            }
        }
        if (targetsToDelete.count > 0) {
            // add the projectile to the list of ones to remove
            [shurikensToDelete addObject:shuriken];
        }
    }
    
    // remove all the projectiles that hit.
    for (CCSprite *shuriken in shurikensToDelete) {
        [_shurikens removeObject:shuriken];
        [self removeChild:shuriken cleanup:YES];
    }
    // Finally, destroy all BACKGROUND layer tiles that were here
}

#pragma mark - Helpers
- (void) setViewpointCenter:(CGPoint) position
{
    CGSize winSize = [[CCDirector sharedDirector] winSize];
    
    int x = MAX(position.x, winSize.width/2);
    int y = MAX(position.y, winSize.height/2);
    x = MIN(x, (_tileMap.mapSize.width * [self pixelToPointSize:_tileMap.tileSize].width) - winSize.width/2);
    y = MIN(y, (_tileMap.mapSize.height * [self pixelToPointSize:_tileMap.tileSize].height) - winSize.height/2);
    CGPoint actualPosition = ccp(x, y);
    
    CGPoint centerOfView = ccp(winSize.width/2, winSize.height/2);
    CGPoint viewPoint = ccpSub(centerOfView, actualPosition);
    self.position = viewPoint;
}

-(void) setPlayerPosition:(CGPoint) position
{
    CGPoint tileCoord = [self tileCoordForPosition:position];
    int tileGid = [_meta tileGIDAt:tileCoord];  // GID is the ID for this kind of tile
    if(tileGid)
    {
        NSDictionary* properties = [_tileMap propertiesForGID:tileGid];
        //
        if(properties)
        {
            // IS this tile a "collidable" tile?
            // if the target move tile is collidable, then simply return and don't set player position to the target
            NSString* collision = [properties valueForKey:@"Collidable"];
            if(collision && [collision compare:@"True"] == NSOrderedSame)
            {
                // ran into a wall sound
                [[SimpleAudioEngine sharedEngine] playEffect:@"hit.caf"];
                return;
            }
            // IS this tile a "collectable" tile?
            NSString *collectable = [properties valueForKey:@"Collectable"];
            if (collectable && [collectable compare:@"True"] == NSOrderedSame)
            {
                // got the item sound
                [[SimpleAudioEngine sharedEngine] playEffect:@"DMLifePack.m4r"];
                // removing from both meta layer AND foreground means we can no longer see OR "collect" the item
                [_meta removeTileAt:tileCoord];
                [_foreground removeTileAt:tileCoord];
                
                self.player.numMelons++;
                //                [_hud numCollectedChanged:_numCollected];
                
                // check win condition then end game if win
                // put the number of melons on your map in place of the '2'
                if (self.player.numMelons == kMaxMelons)
                    [self win];
            }
        }
    }
    
    self.player.sprite.position = position;
}

// there are iOS coordinates coresponding to the pixels starting with 0,0 at BOTTOM left corner...
// then there are tile index coordinates starting from 0,0 at TOP left corner
// we will need the tile coordinate for some purposes:
-(CGPoint) tileCoordForPosition:(CGPoint) position
{
    int x = position.x / [self pixelToPointSize:_tileMap.tileSize].width;
    // gotta flip in y-direction
    int y = ((_tileMap.mapSize.height * [self pixelToPointSize:_tileMap.tileSize].height) - position.y) / [self pixelToPointSize:_tileMap.tileSize].height;
    return ccp(x,y);
}

-(CGPoint) pixelToPoint:(CGPoint) pixelPoint{
    return ccpMult(pixelPoint, 1/CC_CONTENT_SCALE_FACTOR());
}

-(CGSize) pixelToPointSize:(CGSize) pixelSize{
    return CGSizeMake((pixelSize.width / CC_CONTENT_SCALE_FACTOR()), (pixelSize.height / CC_CONTENT_SCALE_FACTOR()));
}

#pragma mark - Touch Handling
// registering ourself as the as the listener for touch events, meaning ccTouchBegan and ccTouchEnded will be called back
-(void) registerWithTouchDispatcher
{
    [[[CCDirector sharedDirector] touchDispatcher] addTargetedDelegate:self priority:0 swallowsTouches:YES];
    //depricated call: [[CCTouchDispatcher sharedDispatcher] addTargetedDelegate:self priority:0 swallowsTouches:YES];
}

- (BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    return YES;
}

 - (void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
    _isSwipe = YES;
    
    // otherwise, test for can test for another kind of move gesture

//    UITouch *touch = [touches anyObject];
//    CGPoint new_location = [touch locationInView: [touch view]];
//    new_location = [[CCDirector sharedDirector] convertToGL:new_location];
    
//    CGPoint oldTouchLocation = [touch previousLocationInView:touch.view];
//    oldTouchLocation = [[CCDirector sharedDirector] convertToGL:oldTouchLocation];
//    oldTouchLocation = [self convertToNodeSpace:oldTouchLocation];
    
    // add my touches to the naughty touch array
//    [myToucharray addObject:NSStringFromCGPoint(new_location)];
//    [myToucharray addObject:NSStringFromCGPoint(oldTouchLocation)];
    
 
}

- (void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
    if (_roundHasStarted != YES)
        return;
    
    if((_isSwipe == YES) && (self.player.numMissiles > 0))
    {
        DLog(@"GOT MISSILES");
        
        _isSwipe = NO; // finger swipe bool for touchesMoved callback
     
        CGPoint touchLocation = [touch locationInView: [touch view]];
        touchLocation = [[CCDirector sharedDirector] convertToGL: touchLocation];
        touchLocation = [self convertToNodeSpace:touchLocation];
//        isSwipe = NO; // finger swipe bool for touchesMoved callback

        // Create a missile and put it at the player's location
        CCSprite* missile = [CCSprite spriteWithFile:@"missile.png"];
        // draw a line between player and last touch
        
        missile.position = _player.sprite.position;
        [self addChild:missile];
        
        // send it on a line from player position to new_location
        
        
        // Determine where we want to shoot the projectile to
        int realX, realY;

        // Are we shooting to the left or right?
        CGPoint diff = ccpSub(touchLocation, _player.sprite.position);
        realX = missile.position.x + diff.x;
        realY = missile.position.y + diff.y;
/*
        if(diff.x > 0)
            realX = (_tileMap.mapSize.width * [self pixelToPointSize:_tileMap.tileSize].width) + (missile.contentSize.width/2);
        else
            realX = -(_tileMap.mapSize.width * [self pixelToPointSize:_tileMap.tileSize].width) - (missile.contentSize.width/2);
*/
//        float ratio = (float) diff.y / (float) diff.x;
//        realY = ((realX - missile.position.x) * ratio) + missile.position.y;
        CGPoint realDest = ccp(realX, realY);
        
        // Determine the length of how far we're shooting
        int offRealX = realX - missile.position.x;
        int offRealY = realY - missile.position.y;
        float length = sqrtf((offRealX*offRealX) + (offRealY*offRealY));
        float velocity = 240/1; // 480pixels/1sec
        float realMoveDuration = length/velocity;
        
        // Determine angle for the missile to face
        // basic trig stuff using touch info a character position calculations from above
        float angleRadians = atanf((float)offRealY / (float)offRealX);
        float angleDegrees = CC_RADIANS_TO_DEGREES(angleRadians);
        float cocosAngle = -1 * angleDegrees - 90;
        if(touchLocation.x > missile.position.x)
            cocosAngle += 180;
//        [missile setRotation:cocosAngle];
        missile.rotation = cocosAngle;
            
            
        // Move projectile to the last touch position
        id actionMoveDone = [CCCallFuncN actionWithTarget:self selector:@selector(missileMoveFinished:)];
        [missile runAction:[CCSequence actionOne:
                            [CCMoveTo actionWithDuration:realMoveDuration position:realDest]
                                                 two:actionMoveDone]];
        [[SimpleAudioEngine sharedEngine] playEffect:@"missileSound.m4a"];
        // we need to keep a reference to each shuriken so we can delete it if it makes a collision with a target
        [_missiles addObject:missile];
        self.player.numMissiles--;
//        [_hud numMissilesChanged:_numMissiles];
    }
    else if(_player.mode == DVPlayerMode_Moving)
    {
        CGPoint touchLocation = [touch locationInView: [touch view]];
        touchLocation = [[CCDirector sharedDirector] convertToGL: touchLocation];
        touchLocation = [self convertToNodeSpace:touchLocation];
        // calling convertToNodeSpace method offsets the touch based on how we have moved the layer
        // for example, This is because the touch location will give us coordinates for where the user tapped inside the viewport (for example 100,100). But we might have scrolled the map a good bit so that it actually matches up to (800,800) for example.
        
        //CGSize tileSize = [self pixelToPointSize:tileMap.tileSize];
        
        // this just moves sprite by the one tile of pixels
        CGPoint playerPos = _player.sprite.position;
        CGPoint diff = ccpSub(touchLocation, playerPos);
        if (abs(diff.x) > abs(diff.y)) {
            if (diff.x > 0) {
                playerPos.x += [self pixelToPointSize:_tileMap.tileSize].width;
                //playerPos.x += _tileMap.tileSize.width;
            } else {
                playerPos.x -= [self pixelToPointSize:_tileMap.tileSize].width;
            }
        } else {
            if (diff.y > 0) {
                playerPos.y += [self pixelToPointSize:_tileMap.tileSize].height;
            } else {
                playerPos.y -= [self pixelToPointSize:_tileMap.tileSize].height;
            }
        }
        
        if (playerPos.x <= (_tileMap.mapSize.width * [self pixelToPointSize:_tileMap.tileSize].width) &&
            playerPos.y <= (_tileMap.mapSize.height * [self pixelToPointSize:_tileMap.tileSize].height) &&
            playerPos.y >= 0 &&
            playerPos.x >= 0 )
        {
            // moved the player sound
            [[SimpleAudioEngine sharedEngine] playEffect:@"move.caf"];
            [self setPlayerPosition:playerPos];
        }
        
        [self setViewpointCenter:_player.sprite.position];
    }
    // else if throw shuriken mode
    else if (_player.mode == DVPlayerMode_Shooting && self.player.numShurikens > 0) {
        // Find where the touch point is
        CGPoint touchLocation = [touch locationInView:[touch view]];
        touchLocation = [[CCDirector sharedDirector] convertToGL:touchLocation];
        touchLocation = [self convertToNodeSpace:touchLocation];
        
        // Create a projectile and put it at the player's location
        CCSprite* shuriken = [CCSprite spriteWithFile:@"Projectile.png"];
        shuriken.position = _player.sprite.position;
        [self addChild:shuriken];
        
        // Determine where we want to shoot the projectile to
        int realX;
        
        // Are we shooting to the left or right?
        CGPoint diff = ccpSub(touchLocation, _player.sprite.position);
        if(diff.x > 0)
            realX = (_tileMap.mapSize.width * [self pixelToPointSize:_tileMap.tileSize].width) + (shuriken.contentSize.width/2);
        else
            realX = -(_tileMap.mapSize.width * [self pixelToPointSize:_tileMap.tileSize].width) - (shuriken.contentSize.width/2);
        
        float ratio = (float) diff.y / (float) diff.x;
        int realY = ((realX - shuriken.position.x) * ratio) + shuriken.position.y;
        CGPoint realDest = ccp(realX, realY);
        
        // Determine the length of how far we're shooting
        int offRealX = realX - shuriken.position.x;
        int offRealY = realY - shuriken.position.y;
        float length = sqrtf((offRealX*offRealX) + (offRealY*offRealY));
        float velocity = 480/1; // 480pixels/1sec
        float realMoveDuration = length/velocity;
        
        // Move projectile to actual endpoint
        id actionMoveDone = [CCCallFuncN actionWithTarget:self selector:@selector(shurikenMoveFinished:)];
        [shuriken runAction:[CCSequence actionOne:
                             [CCMoveTo actionWithDuration:realMoveDuration position:realDest]
                                              two:actionMoveDone]];
        [[SimpleAudioEngine sharedEngine] playEffect:@"shurikenSound.m4a"];
        // we need to keep a reference to each shuriken so we can delete it if it makes a collision with a target
        [_shurikens addObject:shuriken];

        self.player.numShurikens--;
    }
}


/*
-(void) addEnemyAtX:(int)x y:(int)y
{
    CCSprite* enemy = [CCSprite spriteWithFile:@"bat.png"];
    enemy.position = ccp(x, y);
    [self addChild:enemy];
    
    // Use our animation method and start the enemy moving toward the player
    [self animateEnemy:enemy];
    [_enemies addObject:enemy];
}
*/

-(void) animateEnemy:(CCSprite*) enemy
{
    //immediately before creating the actions in animateEnemy
    //rotate to face the player
    CGPoint diff = ccpSub(_player.sprite.position, enemy.position);
    float angleRadians = atanf((float)diff.y / (float)diff.x);
    float angleDegrees = CC_RADIANS_TO_DEGREES(angleRadians);
    float cocosAngle = -1 * angleDegrees;
    if(diff.x < 0)
        cocosAngle += 180;
    enemy.rotation = cocosAngle;
    
    // 10 pixels per 0.3 seconds -> speed = 33 pixels / second
    // speed of the enemy
    ccTime actualDuration = 0.3;
    
    // create the actions
    // ccpMult, ccpSub multiplies, subtracts two point coordinates (vectors) to give one resulting point
    // ccpNormalize calculates a unit vector given 2 point coordinates,...
    // and gives a hypotenous of length 1 with appropriate x,y
    id actionMove = [CCMoveBy actionWithDuration:actualDuration position:ccpMult(ccpNormalize(ccpSub(_player.sprite.position,enemy.position)), 10)];
    id actionMoveDone = [CCCallFuncN actionWithTarget:self selector:@selector(enemyMoveFinished:)];
    [enemy runAction:[CCSequence actions:actionMove, actionMoveDone, nil]];
}

// callback that starts another iteration of enemy movement.
// we know which sprite called us here because sender is a CCSprite - the sprite that just finished animating
-(void) enemyMoveFinished:(id)sender
{
    CCSprite* enemy = (CCSprite*) sender;
    
    [self animateEnemy: enemy];
}

-(void) shurikenMoveFinished:(id) sender
{
    CCSprite* sprite = (CCSprite*) sender;
    [self removeChild:sprite cleanup:YES];
    
    [_shurikens removeObject:sprite];  // remove our reference to this shuriken from the projectiles array of sprite objects
}

-(void) missileMoveFinished:(id) sender
{
    CCSprite* sprite = (CCSprite*) sender;
    [self missileExplodes:sprite.position];
    [self removeChild:sprite cleanup:YES];

    [_missiles removeObject:sprite];  // remove our reference to this shuriken from the projectiles array of sprite objects

}

-(void) missileExplodes:(CGPoint) hitLocation
{
    [[SimpleAudioEngine sharedEngine] playEffect:@"missileExplode.m4a"];

    // explode, killing anything in 4 box radius
    CCSprite* explosion = [CCSprite spriteWithFile:@"nuked.png"];
    explosion.position = hitLocation;
    [self addChild:explosion];
 
    // Move projectile to actual endpoint
    id actionMoveDone = [CCCallFuncN actionWithTarget:self selector:@selector(shurikenMoveFinished:)];

//    [explosion runAction:CC]
    id scaleUpAction =  [CCEaseInOut actionWithAction:[CCScaleTo actionWithDuration:1 scaleX:2.0 scaleY:2.5] rate:2.0];
    [explosion runAction:[CCSequence actionOne:scaleUpAction two:actionMoveDone]];

    // make a rectangle that is 2*2 tiles wide, kill everything collided with it (including destructable tiles from tilemap)
    // anything within 2 * the explosion images bounding box gets killed (explosion will expand to 2 times size)
    CGRect explosionArea = CGRectMake(explosion.position.x - (explosion.contentSize.width/2)*2, explosion.position.y - (explosion.contentSize.height/2)*2, explosion.contentSize.width*2, explosion.contentSize.height*2);

    // First, if the explosion hit YOU then you're dead
    if(CGRectIntersectsRect(explosionArea, _player.sprite.boundingBox))
    {
        [self lose];
        // [self schedule:@selector(lose) interval:0.75];
    }

    
    // iterate through enemies, see if any intersect with current projectile
    NSMutableArray *targetsToDelete = [[NSMutableArray alloc] init];
    for (Bat *target in [_player.minions allValues]) {
        // enemy down!
        if(CGRectIntersectsRect(explosionArea, target.sprite.boundingBox))
        {
            [target takeDamage:2];
//            self.player.numKills += 1;
//            [_hud numKillsChanged:_numKills];
            [targetsToDelete addObject:target];
//            [[SimpleAudioEngine sharedEngine] playEffect:@"juliaRoar.m4a"];
        }
    }
    
    // delete all hit enemies
    for (Bat *target in targetsToDelete) {
        if(target.hitPoints < 1)
        {
            [[SimpleAudioEngine sharedEngine] playEffect:@"DMZombiePain.m4r"];
            [target kill];
            self.player.numKills += 1;
//            [_hud numKillsChanged:_numKills];
                //[_player.minions removeObject:target];
            [self.player.minions removeObjectForKey:[NSNumber numberWithInt:target.uniqueID]];
            // [self removeChild:target cleanup:YES];
        }
    }
    
    // Finally, detroy any background layer tiles that were here, scorched earth! Everything anhialated!

    CGPoint bottomLeft = CGPointMake(explosionArea.origin.x + explosionArea.size.width * 0.26, explosionArea.origin.y + explosionArea.size.height * 0.26);
    CGPoint bottomRight = CGPointMake(explosionArea.origin.x + explosionArea.size.width * 0.74, explosionArea.origin.y + explosionArea.size.height * 0.26);
    CGPoint topLeft = CGPointMake(explosionArea.origin.x + explosionArea.size.width * 0.26, explosionArea.origin.y + explosionArea.size.height * 0.74);
    CGPoint topRight = CGPointMake(explosionArea.origin.x + explosionArea.size.width * 0.74, explosionArea.origin.y + explosionArea.size.height * 0.74);

    [_background removeTileAt:[self tileCoordForPosition:bottomLeft]];
    [_background removeTileAt:[self tileCoordForPosition:bottomRight]];
    [_background removeTileAt:[self tileCoordForPosition:topLeft]];
    [_background removeTileAt:[self tileCoordForPosition:topRight]];
    
    [_foreground removeTileAt:[self tileCoordForPosition:bottomLeft]];
    [_foreground removeTileAt:[self tileCoordForPosition:bottomRight]];
    [_foreground removeTileAt:[self tileCoordForPosition:topLeft]];
    [_foreground removeTileAt:[self tileCoordForPosition:topRight]];

    [_meta removeTileAt:[self tileCoordForPosition:bottomLeft]];
    [_meta removeTileAt:[self tileCoordForPosition:bottomRight]];
    [_meta removeTileAt:[self tileCoordForPosition:topLeft]];
    [_meta removeTileAt:[self tileCoordForPosition:topRight]];
}

// this might not be necessary since children of our node are cleaned up after the node deallocates itself
-(void) missileExplodesFinished:(id) sender
{
    CCSprite* sprite = (CCSprite*) sender;
    [self removeChild:sprite cleanup:YES];

}

// on "dealloc" you need to release all your retained objects

#pragma mark GameKit delegate

-(void) achievementViewControllerDidFinish:(GKAchievementViewController *)viewController
{
	AppController *app = (AppController*) [[UIApplication sharedApplication] delegate];
	[[app navController] dismissModalViewControllerAnimated:YES];
}

-(void) leaderboardViewControllerDidFinish:(GKLeaderboardViewController *)viewController
{
	AppController *app = (AppController*) [[UIApplication sharedApplication] delegate];
	[[app navController] dismissModalViewControllerAnimated:YES];
}
@end
