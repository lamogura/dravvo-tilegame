
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

//static int NumPlaybacksRunning = 0;
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
+(CCScene *) sceneWithInitType:(CoreGameInitType) type;
{
	CCScene *scene = [CCScene node];
    CoreGameLayer *gameLayer;
    
    switch (type) {
        case NewGameAsHost:
            gameLayer = [[CoreGameLayer alloc] initAsPlayerWithRole:(int)DVPlayerHost];
            break;
        case NewGameAsGuest:
            gameLayer = [[CoreGameLayer alloc] initAsPlayerWithRole:(int)DVPlayerGuest];
            break;
        case LoadSavedGame:
            gameLayer = [[CoreGameLayer alloc] initFromSavedGame];
            break;
        default:
            ULog(@"Some unknown initType sent to CoreGameLayer scene()");
            break;
    }
    gameLayer.tag = kCoreGameLayerTag; // FIX this ugliness, its used to get the layer from the scene obj in the lifecycle

    // store a member var reference to the hud so we can refer back to it to reset the label strings!
    gameLayer.hud = [[CoreGameHudLayer alloc] initWithCoreGameLayer:gameLayer];

 	[scene addChild:gameLayer];
    [scene addChild:gameLayer.hud];

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
	if (self=[super init])
    {
        [self initSettings]; // alloc ivars and set inital vars

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
                _player.deviceToken = [[NSUserDefaults standardUserDefaults] valueForKey:kDeviceToken]; // TODO: remove this, probably not needed
            }
        }

        // don't need to save this as member var - only for opponent instantiation for enemy target
        enum DVPLayerRole opponentRole = (pRole == DVPlayerHost) ? DVPlayerGuest : DVPlayerHost;
        
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
        
        CountdownLayer* cdlayer = [[CountdownLayer alloc] initWithCountdownFrom:3
                                              AndCallBlockWhenCountdownFinished:
                                   ^(id status)
                                    {
                                        [self startRound];
                                    }];
        
        [self.parent addChild:cdlayer];
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

+(NSString*) SavegamePath
{
    NSString *gameID = [[NSUserDefaults standardUserDefaults] objectForKey:kCurrentGameIDKey];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [NSString stringWithFormat:@"%@/%@.plist", [paths objectAtIndex:0], gameID];
}

-(void) saveGameState //TODO add error handling
{
    NSMutableData *data = [[NSMutableData alloc] init];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    
    [archiver encodeObject:self forKey:kCoreGameSavegameKey];
    [archiver finishEncoding];
    [data writeToFile:[CoreGameLayer SavegamePath] atomically:YES];
}

-(id) initFromSavedGame
{
    // Reload all state variables, including map, player, minion instances and display sprites, etc
    NSString* path = [CoreGameLayer SavegamePath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path])
    {
        NSData *codedData = [[NSData alloc] initWithContentsOfFile:path];
        if (codedData != nil)
        {
            NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:codedData];
            self = [unarchiver decodeObjectForKey:kCoreGameSavegameKey];
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
    NSUInteger length = _background.layerSize.width * _background.layerSize.height * sizeof(uint32_t);
    
    NSData* data = [NSData dataWithBytes:_background.tiles length:length];
    [coder encodeObject:data forKey:kCoreGameNSCodingKey_Background];

    data = [NSData dataWithBytes:_destruction.tiles length:length];
    [coder encodeObject:data forKey:kCoreGameNSCodingKey_Destruction];

    data = [NSData dataWithBytes:_foreground.tiles length:length];
    [coder encodeObject:data forKey:kCoreGameNSCodingKey_Foreground];

    data = [NSData dataWithBytes:_meta.tiles length:length];
    [coder encodeObject:data forKey:kCoreGameNSCodingKey_Meta];
    
    [coder encodeObject:self.player forKey:kCoreGameNSCodingKey_Player];
    [coder encodeObject:self.opponent forKey:kCoreGameNSCodingKey_Opponent];
}

- (id)initWithCoder:(NSCoder *)coder
{
    if (self = [self init])
    {
        [self initTilemap];
        
        // CHECK assume all layers are same size
        NSInteger length = _background.layerSize.width * _background.layerSize.height;
        uint32_t data[length];
        
        [[coder decodeObjectForKey:kCoreGameNSCodingKey_Background] getBytes:data];
        [CoreGameLayer setTileArray:data ForLayer:_background];
        
        [[coder decodeObjectForKey:kCoreGameNSCodingKey_Foreground] getBytes:data];
        [CoreGameLayer setTileArray:data ForLayer:_foreground];
        
        [[coder decodeObjectForKey:kCoreGameNSCodingKey_Destruction] getBytes:data];
        [CoreGameLayer setTileArray:data ForLayer:_destruction];
        
        [[coder decodeObjectForKey:kCoreGameNSCodingKey_Meta] getBytes:data];
        [CoreGameLayer setTileArray:data ForLayer:_meta];
        
        // alloc ivars and set inital vars
        [self initSettings];
        
        [self initAudio];
        
        [self addChild:_tileMap z:-1];
        
        _player = [coder decodeObjectForKey:kCoreGameNSCodingKey_Player];
        [self addChild:self.player];
        
        for (Bat* bat in [_player.minions allValues]) {
            bat.gameLayer = self;
            [self addChild:bat];
        }
        
        _opponent = [coder decodeObjectForKey:kCoreGameNSCodingKey_Opponent];
        [self addChild:self.opponent];
        
        for (Bat* bat in [_opponent.minions allValues]) {
            bat.gameLayer = self;
            [self addChild:bat];
        }
        
        [self setViewpointCenter:_player.sprite.position];
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
    // let the game lifecycle listen and handle what to do
    [[NSNotificationCenter defaultCenter] postNotificationName:kCoreGameRoundFinishedNotification object:self];

//    [self saveGameState];
    
    self.isTouchEnabled = NO;
    // temp only - replace with server game data object
    
//    NSArray* allEvents = [EntityNode CompleteEventHistory];
//    DLog(@"allEvents count = %d", [allEvents count]);
//
//    [self playbackEvents:allEvents];
    /*
    // transition to a waiting for opponent scene, ideally displaying current stats (maybe keep HUD up)
    GameOverScene *gameOverScene = [GameOverScene node];
    [gameOverScene.layer.label setString:@"Round Finished!"];
    [[CCDirector sharedDirector] replaceScene:gameOverScene];
     */
}

- (GameOverStatus)getGameOverStatus
{
    // TODO: implement, returning fake value now
    return GameOverStatus_Ongoing;
}

- (void) win {
    [[CCDirector sharedDirector] replaceScene:
     [GameOverLayer sceneWithLabelText:@"You Win!"]];
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

-(void) playbackEvents:(NSArray *)events
{
    int count = 0, beforeCount = 0, others = 0, players = 0;
    for (int timeStep = 0; (float)(timeStep * kReplayTickLengthSeconds) < (float)kTurnLengthSeconds; timeStep++)
    {
        //  DLog(@"MADE IT 1");
        for (NSDictionary* eventInfo in events)
        {
            ++beforeCount;
            if ([[eventInfo objectForKey:kDVEventKey_TimeStepIndex] intValue] != timeStep)
                continue;
            ++count;
            //////  OLD SHIT FROM HERE  ///////
            DLog(@"MADE IT 3");
            
            // pull out the key values
            int ownerID = [[eventInfo objectForKey:kDVEventKey_OwnerID] intValue];  // int
            DVEventType eventType = [[eventInfo objectForKey:kDVEventKey_EventType] intValue];  // DVEventType
            NSString* entityType = [eventInfo objectForKey:kDVEventKey_EntityType];  // FIX: need to change this to an enum of entityType
            int uniqueID = [[eventInfo objectForKey:kDVEventKey_EntityID] intValue]; // int
            
            int hpChange = 0;
            CGPoint location;
//            if (count == 10) {
//                int asdfasdf = 0;
//            }
            // sanity check DEBUG test
            switch (eventType)
            {
                case DVEvent_Wound:  // wound
                    DLog(@"DVEvent_Wound found!");
                    hpChange = [[eventInfo objectForKey:kDVEventKey_HPChange] intValue];
                    break;
                case DVEvent_Spawn: // spawn
                case DVEvent_Move:  // move
                case DVEvent_Kill:  // kill
                    DLog(@"Event needing X,Y Found!");
                    location = ccp([[eventInfo objectForKey:kDVEventKey_CoordX] intValue],
                                   [[eventInfo objectForKey:kDVEventKey_CoordY] intValue]);
                    break;
                default:
                    ULog(@"Unknown EventType!");
                    break;
            }
            
            DLog(@"ownerID %d, eventType %d, entityType %@, uniqueID %d, xCoord %f, yCoord %f",ownerID, eventType, entityType, uniqueID, location.x, location.y);
            
            if ([entityType isEqualToString:kEntityTypePlayer]) // case 1: action to be performed on the thePlayer (_opponent or _player)
            {
                ++players;
                Player* replayPlayer = _opponent; // guess first
                if (uniqueID != replayPlayer.uniqueID)
                    replayPlayer = _player;
                NSAssert(uniqueID == replayPlayer.uniqueID, @"Not finding correct player by uniqueID");

                switch (eventType)
                {
                    case DVEvent_Wound:
                        [replayPlayer animateTakeDamage:hpChange];
                        break;
                    case DVEvent_Move:
                        DLog("cacheing move for _player to point: %f, %f",location.x, location.y);
                        [replayPlayer animateMove:location];
                        break;
                    case DVEvent_Kill:  // This is NOT a real kill as it would be for minions; the Player remains instantiated, just respawns, re-inits, etc
                        [replayPlayer animateKill:location];  // this call takes care of everything, sounds, respawn, re-init
                        // for now, animateKill also takes care of DVEvent_InitStats and DVEvent_Respawn, which are no longer cached anyway
                        break;
                    default:
                        ULog(@"FUCK got a weird eventType in enemyPlaybackLoop's switch");
                        break;
                }
            }
            else // non-player entity
            {
                ++others;
                Player* ownerPlayer = _player; // guess first
                if (ownerID != ownerPlayer.uniqueID)
                    ownerPlayer = _opponent;
                NSAssert(ownerID == ownerPlayer.uniqueID, @"Not finding correct player by ownerID");
                
                DLog("A Player's minions case"); // FIX use right vocab!
                // if this is a minion spawn, must instantiate and add to the minions list with appropriate uniqueID
                const ccTime delay = _timeStepIndex * kReplayTickLengthSeconds;
                
                switch (eventType)
                {
                    case DVEvent_Spawn:
                        if([entityType isEqualToString:kEntityTypeBat])
                        {
                            DLog(@"Spawning a bat...");
                            // NOTE: using *WithoutCache init method, so this spawn isn't logged again on the other player's device
                            //                 EntityNode *minion = [[EntityNode alloc] initInLayerWithoutCache:self
                            //                Bat* minion = [[Bat alloc] initInLayer:self atSpawnPoint:ccp((int)xCoord, (int)yCoord)];
                            Bat *bat = [[Bat alloc] initInLayerWithoutCache_AndAnimate:self
                                                                          atSpawnPoint:location
                                                                          withBehavior:DVCreatureBehaviorDefault
                                                                               ownedBy:ownerPlayer
                                                                          withUniqueID:uniqueID
                                                                            afterDelay:delay];  // amount of time that will have passed til this _timeStepIndex
                            
                            [ownerPlayer.minions addEntriesFromDictionary:
                             [NSDictionary dictionaryWithObject:bat forKey:[NSNumber numberWithInt:bat.uniqueID]]];
                            NSAssert(ownerPlayer.uniqueID == bat.owner.uniqueID, @"Bat owner ID and player ID not matching");
                        }
                        else if([entityType isEqualToString:kEntityTypeMissile])
                        {
                            DLog(@"Spawning a missile...");
                            Missile* missile = [[Missile alloc] initInLayerWithoutCache_AndAnimate:self
                                                                                      atSpawnPoint:location
                                                                                           ownedBy:ownerPlayer
                                                                                      withUniqueID:uniqueID
                                                                                        afterDelay:delay];
                            
                            [_player.missiles addEntriesFromDictionary:
                             [NSDictionary dictionaryWithObject:missile forKey:[NSNumber numberWithInt:missile.uniqueID]]];
                            DLog(@"missile ownedBy: %d == %d",ownerPlayer.uniqueID, missile.owner.uniqueID);
                        }
                        else if([entityType isEqualToString:kEntityTypeShuriken])
                        {
                            DLog(@"Spawning a shuriken...");
                            Shuriken* shuriken = [[Shuriken alloc] initInLayerWithoutCache_AndAnimate:self
                                                                                         atSpawnPoint:location
                                                                                              ownedBy:ownerPlayer
                                                                                         withUniqueID:uniqueID
                                                                                           afterDelay:delay];
                            
                            [_player.shurikens addEntriesFromDictionary:
                             [NSDictionary dictionaryWithObject:shuriken forKey:[NSNumber numberWithInt:shuriken.uniqueID]]];
                            DLog(@"shuriken ownedBy: %d == %d",ownerPlayer.uniqueID, shuriken.owner.uniqueID);
                        }
                        else NSAssert(false, @"Unknown entity type!!!");
                        break;
                    case DVEvent_Wound:
                    case DVEvent_Move:
                    case DVEvent_Kill:
                    {
                        NSDictionary* dictToSearch;
                        if ([entityType isEqualToString:kEntityTypeBat])
                            dictToSearch = ownerPlayer.minions;
                        else if ([entityType isEqualToString:kEntityTypeMissile])
                            dictToSearch = ownerPlayer.missiles;
                        else if ([entityType isEqualToString:kEntityTypeShuriken])
                            dictToSearch = ownerPlayer.shurikens;
                        NSAssert(dictToSearch != NULL, @"Couldnt find dict to search on ownerPlayer");
                        
                        if (eventType == DVEvent_Wound)
                            [[dictToSearch objectForKey:[NSNumber numberWithInt:uniqueID]] animateTakeDamage:hpChange];
                        else if (eventType == DVEvent_Move)
                            [[dictToSearch objectForKey:[NSNumber numberWithInt:uniqueID]] animateMove:location];
                        else if (eventType == DVEvent_Kill)
                            [[dictToSearch objectForKey:[NSNumber numberWithInt:uniqueID]] animateKill:location];
                        else NSAssert(false, @"Whoops forgot add code for this event case");
                    }
                        break;
                    case DVEvent_InitStats:
                    case DVEvent_Respawn:
                        ULog(@"Sorry not yet implemented");
                        break;
                    default:
                        NSAssert(false, @"Unknown event going into switch on playback");
                } //switch (eventType)
            } // else non-player entity
        }  // timeStep for loop
    }
    
    // playback all the events here
    NSMutableArray* allEntities = [NSMutableArray arrayWithObjects: _player, _opponent, nil];
    [allEntities addObjectsFromArray:[_player.minions allValues]];
    [allEntities addObjectsFromArray:[_player.missiles allValues]];
    [allEntities addObjectsFromArray:[_player.shurikens allValues]];
    [allEntities addObjectsFromArray:[_opponent.minions allValues]];
    [allEntities addObjectsFromArray:[_opponent.missiles allValues]];
    [allEntities addObjectsFromArray:[_opponent.shurikens allValues]];
    
    for (EntityNode* entity in allEntities) {
        [entity playActionsInSequence];
    }

    [self setViewpointCenter:_opponent.lastPoint];
    
    // DEBUG temporary
    // now schedule a callback for Our Turn (Player's Turn) after _timeStepIndex * kReplayTickLengthSeconds period
//    [self scheduleOnce:@selector(transitionToNextTurn) delay:(_timeStepIndex * kReplayTickLengthSeconds+2)];
    // pause 2 seconds to allow for explosions and other animations to play before clearing the dead from the dicts
    [self scheduleOnce:@selector(playbackFinished) delay:kTurnLengthSeconds];
}
-(void) playbackFinished
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kCoreGamePlaybackFinishedNotification object:self];
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

    [[CCDirector sharedDirector] replaceScene:
     [GameOverLayer sceneWithLabelText:@"Round Finished!"]];
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

+(void)setTileArray:(uint32_t *)pArray ForLayer:(CCTMXLayer *)pLayer
{
    CGSize size = pLayer.layerSize;
    for (int x = 0; x < size.width; x++)
    {
        for (int y = 0; y < size.height; y++)
        {
            uint32_t tileGid = *(pArray + y*(int)size.width + x);
            [pLayer setTileGID:tileGid at:ccp(x, y)];
        }
    }
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
