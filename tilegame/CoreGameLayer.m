
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
#import "Missile.h"
#import "Shuriken.h"
#import "WeaponNode.h"

#pragma mark - CoreGameLayer

static int NumPlaybacksRunning = 0;
static int NumPlaybacksMethodsRunning = 0;

static DVServerGameData* _serverGameData;

@implementation CoreGameLayer

@synthesize hud = _hud;
@synthesize timeStepIndex = _timeStepIndex;
@synthesize eventArrayIndex = _eventArrayIndex;
@synthesize player = _player;
@synthesize opponent = _opponent;
@synthesize historicalEventsDict = _historicalEventsDict;
@synthesize collidableProjectiles = _collidableProjectiles;
//@synthesize eventHistory = _eventHistory;

@synthesize roundTimer = _roundTimer;

+(void) setServerGameData:(DVServerGameData*) gameData  // static to store last game data update
{
    if(_serverGameData == nil)
        _serverGameData = [[DVServerGameData alloc] init];
    _serverGameData = gameData;
}

+(void) changeNumPlaybacksRunningBy:(int)increment
{
    NumPlaybacksMethodsRunning += increment;
}

// Helper class method that creates a Scene with the HelloWorldLayer as the only child.
// What calls this class??
+(CCScene *) scene:(DVCoreLayerType) initType
{
	CCScene *scene = [CCScene node];
    CoreGameLayer *gameLayer;
    
    switch (initType) {
        case DVNewGameAsHost:
            gameLayer = [[CoreGameLayer alloc] initAsPlayerWithRole:(int)DVPlayerHost];
            break;
        case DVNewGameAsGuest:
            gameLayer = [[CoreGameLayer alloc] initAsPlayerWithRole:(int)DVPlayerGuest];
            break;
        case DVLoadFromFile:
            gameLayer = [[CoreGameLayer alloc] initFromSavedGameState];
            break;
        default:
            ULog(@"Some unknown initType sent to CoreGameLayer scene()");
            break;
    }

    CoreGameHudLayer* hud = [[CoreGameHudLayer alloc] initWithCoreGameLayer:gameLayer];
    
    gameLayer.hud = hud;  // store a member var reference to the hud so we can refer back to it to reset the label strings!
    
 	[scene addChild:gameLayer];
    [scene addChild:hud];

    CountdownLayer* cdlayer = [[CountdownLayer alloc] initWithCountdownFrom:3 AndCallBlockWhenCountdownFinished:^(id status) {
        [gameLayer startRound];
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

-(id) initAsPlayerWithRole:(int) pRole
{
	if(self=[super init]) {
        
        // alloc ivars and set inital vars
        [self initSettings];

        [self initAudio];
        
        [self initTilemap];

        
        CCTMXObjectGroup* playerSpawnObjects = [_tileMap objectGroupNamed:@"PlayerSpawnPoints"];
        NSAssert(playerSpawnObjects != nil, @"'PlayerSpawnPoints' object group not found");

        // init local player from tilemap
        NSDictionary* spawnPointsDict = [[NSDictionary alloc] init];
        for(spawnPointsDict in [playerSpawnObjects objects])
        {   // _player has not been instantiated yet, so check [Player nextUniqueID]
            if([[spawnPointsDict valueForKey:@"Owner"] intValue] == (int)pRole)
            {
                CGPoint playerSpawnPoint = [self pixelToPoint: ccp([[spawnPointsDict valueForKey:@"x"] intValue],[[spawnPointsDict valueForKey:@"y"] intValue])];
                DLog(@"CGPoint:%f,%f",playerSpawnPoint.x,playerSpawnPoint.y);
                
                _player = [[Player alloc] initInLayer:self atSpawnPoint:playerSpawnPoint withUniqueIntID:(int)pRole withShurikens:kInitShurikens withMissles:kInitMissiles];
            }
        }

        // don't need to save this as member var - only for opponent instantiation for enemy target
        DVPLayerRole opponentRole = (pRole == DVPlayerHost) ? DVPlayerGuest : DVPlayerHost;
        
        // DEBUG for now, spawn opponent as Player 2 (assuming we are host not guest
        for(spawnPointsDict in [playerSpawnObjects objects])
        {   // _player has not been instantiated yet, so check [Player nextUniqueID]
            if([[spawnPointsDict valueForKey:@"Owner"] intValue] == (int)opponentRole)
            {
                CGPoint playerSpawnPoint = [self pixelToPoint: ccp([[spawnPointsDict valueForKey:@"x"] intValue],[[spawnPointsDict valueForKey:@"y"] intValue])];
                DLog(@"CGPoint:%f,%f",playerSpawnPoint.x,playerSpawnPoint.y);
                
                _opponent = [[Player alloc] initInLayer:self atSpawnPoint:playerSpawnPoint withUniqueIntID:(int)opponentRole withShurikens:kInitShurikens withMissles:kInitMissiles];
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

//case DVBeginNextTurn:  // didn't get here unless DVServerGameData was packed with the opponent's goods
//{
//    [self reloadGameState];  // reload the current game state before replay and play
//    [self setViewpointCenter:_player.sprite.position];
//    [self addChild:_tileMap z:-1];
//    
//    [NSThread sleepForTimeInterval:2];  // seconds?
//    //                [self enemyPlaybackLoop:0];  // call the opponent round playback method before our turn
//    
//    [self setViewpointCenter:_player.sprite.position];  // change the view back again to player
//    [self addChild:_tileMap z:-1];
//    
//    self.isTouchEnabled = YES;  // set THIS LAYER as touch enabled so user can move character around with callbacks
//    _isSwipe = NO; // what does this do?
//    _touches = [[NSMutableArray alloc ] init]; // store the touches for missile launching
//}

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
    [coder encodeInt:*(_background.tiles) forKey:CoreGameBackgroundTilesKey];
    [coder encodeInt:*(_destruction.tiles) forKey:CoreGameDestructionTilesKey];
    [coder encodeInt:*(_foreground.tiles) forKey:CoreGameForegroundTilesKey];
    [coder encodeInt:*(_meta.tiles) forKey:CoreGameMetaTilesKey];
    [coder encodeObject:self.player forKey:CoreGamePlayerKey];
    [coder encodeObject:self.opponent forKey:CoreGameOpponentKey];
}

- (id)initWithCoder:(NSCoder *)coder
{
    if (self = [self init])
    {
        uint32_t intVal;
        
        intVal = [coder decodeIntForKey:CoreGameBackgroundTilesKey];
        _background.tiles = &(intVal);
        intVal = [coder decodeIntForKey:CoreGameDestructionTilesKey];
        _destruction.tiles = &(intVal);
        intVal = [coder decodeIntForKey:CoreGameForegroundTilesKey];
        _foreground.tiles = &(intVal);
        intVal = [coder decodeIntForKey:CoreGameMetaTilesKey];
        _meta.tiles = &(intVal);

        // alloc ivars and set inital vars
        [self initSettings];
        
        [self initAudio];
        
        [self initTilemap];
        [self addChild:_tileMap z:-1];
        
        _player = [coder decodeObjectForKey:CoreGamePlayerKey];
        [self addChild:self.player];
        
        for (Bat* bat in [_player.minions allValues]) {
            bat.gameLayer = self;
            [self addChild:bat];
        }
        
        _opponent = [coder decodeObjectForKey:CoreGameOpponentKey];
        [self addChild:self.opponent];
        
        for (Bat* bat in [_opponent.minions allValues]) {
            bat.gameLayer = self;
            [self addChild:bat];
        }
        
        [self setViewpointCenter:_player.sprite.position];
//        self.opponent = [coder decodeObjectForKey:CoreGameOpponentKey];
    }
    return self;
}

-(void) initSettings
{
    _apiWrapper = [[DVAPIWrapper alloc] init]; // init the wrapper class for the api
    _collidableProjectiles = [[NSMutableDictionary alloc] init];
    
    // touches
    _touches = [[NSMutableArray alloc ] init]; // store the touches for missile launching
    self.isTouchEnabled = YES;  // set THIS LAYER as touch enabled so user can move character around with callbacks
    _isSwipe = NO; // what does this do?
    
    // round init
    _timeStepIndex = 0; // step index for caching events
    _roundHasStarted = NO; // wait for startRound()
    self.roundTimer = (float) kTurnLengthSeconds;
    
    _timeStepIndex = 0; // step index for caching events
    //        _eventHistory = [[NSMutableArray alloc] init];
}

-(void) initTilemap
{
    // load the TileMap and the tile layers
    _tileMap = [CCTMXTiledMap tiledMapWithTMXFile:@"TileMap.tmx"];
    _background = [_tileMap layerNamed:@"Background"];
    _meta = [_tileMap layerNamed:@"Meta"];
    _foreground = [_tileMap layerNamed:@"Foreground"];
    _destruction = [_tileMap layerNamed:@"Destruction"];
    _meta.visible = NO;
}

-(void) initAudio
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
//    [self saveGameState];
    
    self.isTouchEnabled = NO;
    // temp only - replace with server game data object
    eventsArray = [NSMutableArray arrayWithArray:[EntityNode eventHistory]]; // NSMutableArray*
    DLog(@"eventsArray count = %d",[eventsArray count]);

    [self enemyPlaybackLoop];
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
    
    for (EntityNode* minion in [_player.minions allValues])
        [minion realUpdate];
    
    for(EntityNode* weapon in [_player.missiles allValues])
        [weapon realUpdate];
    
    for(EntityNode* weapon in [_player.shurikens allValues])
        [weapon realUpdate];
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
    
    for (EntityNode *weapon in [_player.missiles allValues])
        [weapon sampleCurrentPosition];

    for (EntityNode *weapon in [_player.shurikens allValues])
        [weapon sampleCurrentPosition];

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

 
-(void) enemyPlaybackLoop
{
    // cycle over timeIndex
    NSDictionary* event; // = [[NSMutableArray alloc] init];  // just setting pointer
    _eventArrayIndex = 0;
    for(_timeStepIndex = 0; _timeStepIndex * kReplayTickLengthSeconds < kTurnLengthSeconds; _timeStepIndex++)
    {
        //  DLog(@"MADE IT 1");
        
        for(event = (NSDictionary*) [eventsArray objectAtIndex:_eventArrayIndex];
            (_eventArrayIndex < [eventsArray count]) && ([(NSNumber*)[(NSDictionary*) [eventsArray objectAtIndex:_eventArrayIndex] objectForKey:kDVEventKey_TimeStepIndex] isEqualToNumber:[NSNumber numberWithInt:_timeStepIndex]]) == YES;
            _eventArrayIndex++)
        {
            event = (NSDictionary*) [eventsArray objectAtIndex:_eventArrayIndex];
            //////  OLD SHIT FROM HERE  ///////
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
                        [thePlayer animateKill:ccp(xCoord, yCoord)];  // this call takes care of everything, sounds, respawn, re-init
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
                
            }
            else  // case 2: action goes to a player's minion
            {
                DLog("A Player's minions case");
                // if this is a minion spawn, must instantiate and add to the minions list with appropriate uniqueID
                if(eventType == DVEvent_Spawn)
                {
                    if(ownerID == _player.uniqueID)
                    {
                        if([entityType isEqualToString:kEntityTypeBat])
                        {
                            DLog(@"Spawning a bat...");
                            // NOTE: using *WithoutCache init method, so this spawn isn't logged again on the other player's device
                            //                 EntityNode *minion = [[EntityNode alloc] initInLayerWithoutCache:self
                            //                Bat* minion = [[Bat alloc] initInLayer:self atSpawnPoint:ccp((int)xCoord, (int)yCoord)];
                            Bat *minion = [[Bat alloc] initInLayerWithoutCache_AndAnimate:self
                                                                             atSpawnPoint:ccp(xCoord, yCoord)
                                                                             withBehavior:DVCreatureBehaviorDefault
                                                                                  ownedBy:_player
                                                                             withUniqueID:uniqueID
                                                                               afterDelay:(_timeStepIndex * kReplayTickLengthSeconds)];  // amount of time that will have passed til this _timeStepIndex
                     
                            [_player.minions addEntriesFromDictionary:[NSDictionary dictionaryWithObject:minion forKey:[NSNumber numberWithInt:minion.uniqueID]]];
                            DLog(@"minion ownedBy: %d == %d",_player.uniqueID, minion.owner.uniqueID);
                        }
                        else if([entityType isEqualToString:kEntityTypeMissile])
                        {
                            DLog(@"Spawning a missile...");
                            Missile* missile = [[Missile alloc] initInLayerWithoutCache_AndAnimate:self
                                                                                      atSpawnPoint:ccp(xCoord, yCoord)
                                                                                           ownedBy:_player
                                                                                      withUniqueID:uniqueID
                                                                                        afterDelay:(_timeStepIndex * kReplayTickLengthSeconds)];
                            
                            [_player.missiles addEntriesFromDictionary:[NSDictionary dictionaryWithObject:missile forKey:[NSNumber numberWithInt:missile.uniqueID]]];
                            DLog(@"missile ownedBy: %d == %d",_player.uniqueID, missile.owner.uniqueID);
                        }
                        else if([entityType isEqualToString:kEntityTypeShuriken])
                        {
                            DLog(@"Spawning a shuriken...");
                            Shuriken* shuriken = [[Shuriken alloc] initInLayerWithoutCache_AndAnimate:self
                                                                                      atSpawnPoint:ccp(xCoord, yCoord)
                                                                                           ownedBy:_player
                                                                                      withUniqueID:uniqueID
                                                                                        afterDelay:(_timeStepIndex * kReplayTickLengthSeconds)];
                            
                            [_player.shurikens addEntriesFromDictionary:[NSDictionary dictionaryWithObject:shuriken forKey:[NSNumber numberWithInt:shuriken.uniqueID]]];
                            DLog(@"shuriken ownedBy: %d == %d",_player.uniqueID, shuriken.owner.uniqueID);
                        }
                        
                    }
                    else if (ownerID == _opponent.uniqueID)
                    {
                        if([entityType isEqualToString:kEntityTypeBat])
                        {
                            DLog(@"Spawning a bat...");
                            // NOTE: using *WithoutCache init method, so this spawn isn't logged again on the other player's device
                            //                 EntityNode *minion = [[EntityNode alloc] initInLayerWithoutCache:self
                            //                Bat* minion = [[Bat alloc] initInLayer:self atSpawnPoint:ccp((int)xCoord, (int)yCoord)];
                            Bat *minion = [[Bat alloc] initInLayerWithoutCache_AndAnimate:self
                                                                             atSpawnPoint:ccp(xCoord, yCoord)
                                                                             withBehavior:DVCreatureBehaviorDefault
                                                                                  ownedBy:_opponent
                                                                             withUniqueID:uniqueID
                                                                               afterDelay:(_timeStepIndex * kReplayTickLengthSeconds)];  // amount of time that will have passed til this _timeStepIndex
                            
                            [_opponent.minions addEntriesFromDictionary:[NSDictionary dictionaryWithObject:minion forKey:[NSNumber numberWithInt:minion.uniqueID]]];
                            DLog(@"minion ownedBy: %d == %d",_opponent.uniqueID, minion.owner.uniqueID);
                        }
                        else if([entityType isEqualToString:kEntityTypeMissile])
                        {
                            DLog(@"Spawning a missile...");
                            Missile* missile = [[Missile alloc] initInLayerWithoutCache_AndAnimate:self
                                                                                      atSpawnPoint:ccp(xCoord, yCoord)
                                                                                           ownedBy:_opponent
                                                                                      withUniqueID:uniqueID
                                                                                        afterDelay:(_timeStepIndex * kReplayTickLengthSeconds)];
                            
                            [_opponent.missiles addEntriesFromDictionary:[NSDictionary dictionaryWithObject:missile forKey:[NSNumber numberWithInt:missile.uniqueID]]];
                            DLog(@"missile ownedBy: %d == %d",_opponent.uniqueID, missile.owner.uniqueID);
                        }
                        else if([entityType isEqualToString:kEntityTypeShuriken])
                        {
                            DLog(@"Spawning a shuriken...");
                            Shuriken* shuriken = [[Shuriken alloc] initInLayerWithoutCache_AndAnimate:self
                                                                                         atSpawnPoint:ccp(xCoord, yCoord)
                                                                                              ownedBy:_opponent
                                                                                         withUniqueID:uniqueID
                                                                                           afterDelay:(_timeStepIndex * kReplayTickLengthSeconds)];
                            
                            [_opponent.shurikens addEntriesFromDictionary:[NSDictionary dictionaryWithObject:shuriken forKey:[NSNumber numberWithInt:shuriken.uniqueID]]];
                            DLog(@"shuriken ownedBy: %d == %d",_opponent.uniqueID, shuriken.owner.uniqueID);
                        }
                    }

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
                else if(ownerID == _player.uniqueID)
                {
                    if([entityType isEqualToString:kEntityTypeBat])
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
//                            [EntityNode animateDeathForEntityType:entityType at:((Bat*)[_player.minions objectForKey:[NSNumber numberWithInt:uniqueID]]).sprite.position]; // TO DO implement the static call for each entityType
                                [((EntityNode*)[_player.minions objectForKey:[NSNumber numberWithInt:uniqueID]]) animateKill:ccp(xCoord, yCoord)];
                            //                    [self.player.minions removeObjectForKey:[NSNumber numberWithInt:uniqueID]];
                            }
                                break;
                            default:
                                DLog(@"FUCK got a weird eventType in enemyPlaybackLoop's switch");
                                break;
                        }
                    }
                    else if([entityType isEqualToString:kEntityTypeMissile])
                    {
                        DLog(@"[_player.missiles count] = %d",[_player.missiles count]);
                        DLog(@"_player's missiles");
                        switch (eventType) {
                            case DVEvent_Wound:
                                [((EntityNode*)[_player.missiles objectForKey:[NSNumber numberWithInt:uniqueID]]) animateTakeDamage:hpChange];
                                break;
                            case DVEvent_Move:
                            {
                                DLog(@"_player's Missile is moving");
                                [((EntityNode*)[_player.missiles objectForKey:[NSNumber numberWithInt:uniqueID]]) animateMove:ccp(xCoord, yCoord)];
                                DLog(@"Missile is done moving");
                            }
                                break;
                            case DVEvent_Kill:
                            {
                                //                            [EntityNode animateDeathForEntityType:entityType at:((Bat*)[_player.minions objectForKey:[NSNumber numberWithInt:uniqueID]]).sprite.position]; // TO DO implement the static call for each entityType
                                [((EntityNode*)[_player.missiles objectForKey:[NSNumber numberWithInt:uniqueID]]) animateKill:ccp(xCoord, yCoord)];
                                //                    [self.player.minions removeObjectForKey:[NSNumber numberWithInt:uniqueID]];
                               
                            }
                                break;
                            default:
                                DLog(@"FUCK got a weird eventType in enemyPlaybackLoop's switch");
                                break;
                        }
                    }
                    else if([entityType isEqualToString:kEntityTypeShuriken])
                    {
                        DLog(@"[_player.shurikens count] = %d",[_player.shurikens count]);
                        DLog(@"_player's shuriken");
                        switch (eventType) {
                            case DVEvent_Wound:
                                [((EntityNode*)[_player.shurikens objectForKey:[NSNumber numberWithInt:uniqueID]]) animateTakeDamage:hpChange];
                                break;
                            case DVEvent_Move:
                            {
                                DLog(@"_player's Shuriken is moving");
                                [((EntityNode*)[_player.shurikens objectForKey:[NSNumber numberWithInt:uniqueID]]) animateMove:ccp(xCoord, yCoord)];
                                DLog(@"Shuriken is done moving");
                            }
                                break;
                            case DVEvent_Kill:
                            {
                                //                            [EntityNode animateDeathForEntityType:entityType at:((Bat*)[_player.minions objectForKey:[NSNumber numberWithInt:uniqueID]]).sprite.position]; // TO DO implement the static call for each entityType
                                [((EntityNode*)[_player.shurikens objectForKey:[NSNumber numberWithInt:uniqueID]]) animateKill:ccp(xCoord, yCoord)];
                                //                    [self.player.minions removeObjectForKey:[NSNumber numberWithInt:uniqueID]];
                                
                            }
                                break;
                            default:
                                DLog(@"FUCK got a weird eventType in enemyPlaybackLoop's switch");
                                break;
                        }
                    }
                    else
                        DLog(@"FUCK got a weird entityType in enemyPlaybackLoop's switch");

                }
                else if(ownerID == _opponent.uniqueID)  // case: _opponent
                {
                    if([entityType isEqualToString:kEntityTypeBat])
                    {
                        DLog(@"[_opponent.minions count] = %d",[_opponent.minions count]);
                        DLog(@"_opponent's bats");
                        switch (eventType) {
                            case DVEvent_Wound:
                                [((EntityNode*)[_opponent.minions objectForKey:[NSNumber numberWithInt:uniqueID]]) animateTakeDamage:hpChange];
                                break;
                            case DVEvent_Move:
                            {
                                DLog(@"_opponent's Bat is moving");
                                [((EntityNode*)[_opponent.minions objectForKey:[NSNumber numberWithInt:uniqueID]]) animateMove:ccp(xCoord, yCoord)];
                                DLog(@"Bat is done moving");
                            }
                                break;
                            case DVEvent_Kill:
                            {
                                //                            [EntityNode animateDeathForEntityType:entityType at:((Bat*)[_opponent.minions objectForKey:[NSNumber numberWithInt:uniqueID]]).sprite.position]; // TO DO implement the static call for each entityType
                                [((EntityNode*)[_opponent.minions objectForKey:[NSNumber numberWithInt:uniqueID]]) animateKill:ccp(xCoord, yCoord)];
                                //                    [self.player.minions removeObjectForKey:[NSNumber numberWithInt:uniqueID]];
                            }
                                break;
                            default:
                                DLog(@"FUCK got a weird eventType in enemyPlaybackLoop's switch");
                                break;
                        }
                    }
                    else if([entityType isEqualToString:kEntityTypeMissile])
                    {
                        DLog(@"[_opponent.missiles count] = %d",[_opponent.missiles count]);
                        DLog(@"_opponent's missiles");
                        switch (eventType) {
                            case DVEvent_Wound:
                                [((EntityNode*)[_opponent.missiles objectForKey:[NSNumber numberWithInt:uniqueID]]) animateTakeDamage:hpChange];
                                break;
                            case DVEvent_Move:
                            {
                                DLog(@"_opponent's Bat is moving");
                                [((EntityNode*)[_opponent.missiles objectForKey:[NSNumber numberWithInt:uniqueID]]) animateMove:ccp(xCoord, yCoord)];
                                DLog(@"Bat is done moving");
                            }
                                break;
                            case DVEvent_Kill:
                            {
                                //                            [EntityNode animateDeathForEntityType:entityType at:((Bat*)[_opponent.minions objectForKey:[NSNumber numberWithInt:uniqueID]]).sprite.position]; // TO DO implement the static call for each entityType
                                [((EntityNode*)[_opponent.missiles objectForKey:[NSNumber numberWithInt:uniqueID]]) animateKill:ccp(xCoord, yCoord)];
                                //                    [self.player.minions removeObjectForKey:[NSNumber numberWithInt:uniqueID]];
                            }
                                break;
                            default:
                                DLog(@"FUCK got a weird eventType in enemyPlaybackLoop's switch");
                                break;
                        }
                    }
                    else if([entityType isEqualToString:kEntityTypeShuriken])
                    {
                        DLog(@"[_opponent.shurikens count] = %d",[_opponent.shurikens count]);
                        DLog(@"_opponent's shuriken");
                        switch (eventType) {
                            case DVEvent_Wound:
                                [((EntityNode*)[_opponent.shurikens objectForKey:[NSNumber numberWithInt:uniqueID]]) animateTakeDamage:hpChange];
                                break;
                            case DVEvent_Move:
                            {
                                DLog(@"_opponent's Shuriken is moving");
                                [((EntityNode*)[_opponent.shurikens objectForKey:[NSNumber numberWithInt:uniqueID]]) animateMove:ccp(xCoord, yCoord)];
                                DLog(@"Shuriken is done moving");
                            }
                                break;
                            case DVEvent_Kill:
                            {
                                //                            [EntityNode animateDeathForEntityType:entityType at:((Bat*)[_player.minions objectForKey:[NSNumber numberWithInt:uniqueID]]).sprite.position]; // TO DO implement the static call for each entityType
                                [((EntityNode*)[_opponent.shurikens objectForKey:[NSNumber numberWithInt:uniqueID]]) animateKill:ccp(xCoord, yCoord)];
                                //                    [self.player.minions removeObjectForKey:[NSNumber numberWithInt:uniqueID]];
                                
                            }
                                break;
                            default:
                                DLog(@"FUCK got a weird eventType in enemyPlaybackLoop's switch");
                                break;
                        }
                    }
                }
                else
                    DLog(@"BALLS!");
                
            }

            /////  OLD SHIT STOPS HERE
            
            
        }
    }
    
    // playback all the events here
    DLog(@"_player playActionsInSequence");
    [_player playActionsInSequence];
    DLog(@"_opponent playActionsInSequence");
    [_opponent playActionsInSequence];
    int counter = 0;
    for (EntityNode* minion in [_player.minions allValues])  // EntityNode
    {
        counter++;
        DLog(@"_player.minion[%d] playActionsInSequence",counter);
        [minion playActionsInSequence];
    }
    counter = 0;
    for (EntityNode* missile in [_player.missiles allValues])  // EntityNode
    {
        counter++;
        DLog(@"_player.missile[%d] playActionsInSequence",counter);
        [missile playActionsInSequence];
    }
    counter = 0;
    for (EntityNode* shuriken in [_player.shurikens allValues])  // EntityNode
    {
        counter++;
        DLog(@"_player.shuriken[%d] playActionsInSequence",counter);
        [shuriken playActionsInSequence];
    }

    counter = 0;
    for (EntityNode* minion in [_opponent.minions allValues])
    {
        counter++;
        DLog(@"_opponent.minion[%d] playActionsInSequence",counter);
        [minion playActionsInSequence];
    }
    counter = 0;
    for (EntityNode* missile in [_opponent.missiles allValues])
    {
        counter++;
        DLog(@"_opponent.missiles[%d] playActionsInSequence",counter);
        [missile playActionsInSequence];
    }
    counter = 0;
    for (EntityNode* shuriken in [_opponent.shurikens allValues])  // EntityNode
    {
        counter++;
        DLog(@"_opponent.shuriken[%d] playActionsInSequence",counter);
        [shuriken playActionsInSequence];
    }

    // DEBUG temporary
    // now schedule a callback for Our Turn (Player's Turn) after _timeStepIndex * kReplayTickLengthSeconds period
    [self scheduleOnce:@selector(transitionToNextTurn) delay:(_timeStepIndex * kReplayTickLengthSeconds+2)];
    // pause 2 seconds to allow for explosions and other animations to play before clearing the dead from the dicts
    
}

-(void) transitionToNextTurn
{
    // clear the dead things from the dicts
    DLog(@"_player clearing the dead...");
    NSMutableArray* toDelete = [[NSMutableArray alloc] init];
    for (EntityNode* entity in [_player.minions allValues])  // EntityNode
    {
        if(entity.isDead)
        {
            DLog(@"Removing a dead minion");
            [toDelete addObject:entity];
        }

    }
    for (EntityNode* entity in toDelete)
        [_player.minions removeObjectForKey:[NSNumber numberWithInt:entity.uniqueID]];

    [toDelete removeAllObjects];
        
    DLog(@"_player clearing the missiles...");
    for (EntityNode* entity in [_player.missiles allValues])  // EntityNode
    {
        if(entity.isDead)
        {
            DLog(@"Removing a dead missile");
            [toDelete addObject:entity];
        }
        
    }
    for (EntityNode* entity in toDelete)
        [_player.missiles removeObjectForKey:[NSNumber numberWithInt:entity.uniqueID]];

    DLog(@"_player clearing the shurikens...");
    for (EntityNode* entity in [_player.shurikens allValues])  // EntityNode
    {
        if(entity.isDead)
        {
            DLog(@"Removing a dead shuriken");
            [toDelete addObject:entity];
        }
        
    }
    for (EntityNode* entity in toDelete)
        [_player.shurikens removeObjectForKey:[NSNumber numberWithInt:entity.uniqueID]];
    
    
    [toDelete removeAllObjects];

    DLog(@"_opponent clearing the dead...");
    for (EntityNode* entity in [_opponent.minions allValues])  // EntityNode
    {
        if(entity.isDead)
        {
            DLog(@"Removing a dead minion");
            [toDelete addObject:entity];
        }
        
    }
    for (EntityNode* entity in toDelete)
        [_opponent.minions removeObjectForKey:[NSNumber numberWithInt:entity.uniqueID]];
    
    [toDelete removeAllObjects];
    
    for (EntityNode* entity in [_opponent.missiles allValues])  // EntityNode
    {
        if(entity.isDead)
        {
            DLog(@"Removing a dead minion");
            [toDelete addObject:entity];
        }
        
    }
    for (EntityNode* entity in toDelete)
        [_opponent.missiles removeObjectForKey:[NSNumber numberWithInt:entity.uniqueID]];

    DLog(@"_opponent clearing the shurikens...");
    for (EntityNode* entity in [_opponent.shurikens allValues])  // EntityNode
    {
        if(entity.isDead)
        {
            DLog(@"Removing a dead shuriken");
            [toDelete addObject:entity];
        }
        
    }
    for (EntityNode* entity in toDelete)
        [_opponent.shurikens removeObjectForKey:[NSNumber numberWithInt:entity.uniqueID]];

    
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
    // DEBUG!! Change _player to _opponent
    // shurikens hitting enemies?
    NSMutableArray* weaponsToDelete = [[NSMutableArray alloc] init];
    
    // DEBUG: change from EntityNode* to Weapon*
    for(WeaponNode* weapon in [self.collidableProjectiles allValues])
    {
        NSMutableArray *targetsToDelete = [[NSMutableArray alloc] init];

        // iterate through enemies, see if any intersect with current projectile
        for (Bat *target in [_player.minions allValues]) {
            // enemy down!
            if(CGRectIntersectsRect(weapon.sprite.boundingBox, target.sprite.boundingBox))
            {
                [target takeDamage:weapon.damage];  // DEBUG change to [target weapon.damage];
                //                self.player.numKills += 1;
                [weapon collidedWith:target];
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
        if (targetsToDelete.count > 0)
            [weaponsToDelete addObject:weapon];
    }
    
    // remove all the projectiles that hit.
    for (WeaponNode* weapon in weaponsToDelete)
        [self.collidableProjectiles removeObjectForKey:[NSNumber numberWithInt:weapon.uniqueID]];
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
    // missile fire
    if((_isSwipe == YES) && (self.player.numMissiles > 0))
    {
        self.player.numMissiles--;
        _isSwipe = NO; // finger swipe bool for touchesMoved callback
     
        CGPoint touchLocation = [touch locationInView: [touch view]];
        touchLocation = [[CCDirector sharedDirector] convertToGL: touchLocation];
        touchLocation = [self convertToNodeSpace:touchLocation];

        // Create a missile and put it at the player's location
        Missile* missile = [[Missile alloc] initInLayer:self atSpawnPoint:_player.sprite.position withTargetPoint:touchLocation ownedBy:_player];
        [self.player.missiles addEntriesFromDictionary:[NSDictionary dictionaryWithObject:missile forKey:[NSNumber numberWithInt:missile.uniqueID]]];
        
    }
    // shuriken throw
    else if (_player.mode == DVPlayerMode_Shooting && self.player.numShurikens > 0)
    {
        self.player.numShurikens--;
        
        // Find where the touch point is
        CGPoint touchLocation = [touch locationInView:[touch view]];
        touchLocation = [[CCDirector sharedDirector] convertToGL:touchLocation];
        touchLocation = [self convertToNodeSpace:touchLocation];
        
        // Create a shuriken and put it at the player's location
        Shuriken* shuriken = [[Shuriken alloc] initInLayer:self atSpawnPoint:_player.sprite.position withTargetPoint:touchLocation ownedBy:_player];
        [self.player.shurikens addEntriesFromDictionary:[NSDictionary dictionaryWithObject:shuriken forKey:[NSNumber numberWithInt:shuriken.uniqueID]]];
    }
    // _player move
    else if(_player.mode == DVPlayerMode_Moving)
    {
        CGPoint touchLocation = [touch locationInView: [touch view]];
        touchLocation = [[CCDirector sharedDirector] convertToGL: touchLocation];
        touchLocation = [self convertToNodeSpace:touchLocation];
        // calling convertToNodeSpace method offsets the touch based on how we have moved the layer
        // for example, This is because the touch location will give us coordinates for where the user tapped inside the viewport (for example 100,100). But we might have scrolled the map a good bit so that it actually matches up to (800,800) for example.
                
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

}

// FIX: change EntityNode to being a weapon, in the list of weapons
-(void) explosionAt:(CGPoint) hitLocation effectingArea:(CGRect) area infilctingDamage:(int)damage weaponID:(int)weaponID
{
    ccTime delayBeforeDelete = 0;
    
    // First, if the explosion hit YOU then you're dead
    if(CGRectIntersectsRect(area, _player.sprite.boundingBox))
    {
        [self lose];
        // [self schedule:@selector(lose) interval:0.75];
    }

    
    // iterate through enemies, see if any intersect with current projectile
    NSMutableArray *targetsToDelete = [[NSMutableArray alloc] init];
    for (Bat *target in [_player.minions allValues]) {
        // enemy down!
        if(CGRectIntersectsRect(area, target.sprite.boundingBox))
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

    CGPoint bottomLeft = CGPointMake(area.origin.x + area.size.width * 0.26, area.origin.y + area.size.height * 0.26);
    CGPoint bottomRight = CGPointMake(area.origin.x + area.size.width * 0.74, area.origin.y + area.size.height * 0.26);
    CGPoint topLeft = CGPointMake(area.origin.x + area.size.width * 0.26, area.origin.y + area.size.height * 0.74);
    CGPoint topRight = CGPointMake(area.origin.x + area.size.width * 0.74, area.origin.y + area.size.height * 0.74);

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

    //    [self scheduleOnce:block^(void){[_player.missiles removeObjectForKey:[NSNumber numberWithInt:weaponID]]; } delay:2];
    // DEBUG - replace this with code with less overhead (don't need to make an action out of removing weapon from the dict)
    // the action is to pause the sprite for kReplayTickLengthSeconds time
    id actionStall = [CCActionInterval actionWithDuration:delayBeforeDelete];  // DEBUG does this work??
    id actionRemove = [CCCallBlock actionWithBlock:^(void){
        [_player.missiles removeObjectForKey:[NSNumber numberWithInt:weaponID]];
    }];
    
    [self runAction:[CCSequence actionOne:actionStall two:actionRemove]];
    //
}


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
