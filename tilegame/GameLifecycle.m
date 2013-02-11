//
//  GameLifecycle.m
//  tilegame
//
//  Created by mogura on 1/26/13.
//
//

#import "cocos2d.h"
#import "GameLifecycle.h"
#import "DVConstants.h"
#import "DVMacros.h"
#import "LoadingLayer.h"
#import "NewGameLayer.h"
#import "CoreGameLayer.h"
#import "CountdownLayer.h"
#import "AwaitingMoveScene.h"
#import "EntityNode.h"
#import "DVServerGameData.h"
#import "GameConstants.h"

@interface GameLifecycle() {
    CoreGameLayer* _gameLayer;
    DVAPIWrapper* _serverApi;
}
@end

@implementation GameLifecycle

+(GameLifecycle *) startWithOptions:(NSDictionary *)launchOptions;
{
    GameLifecycle* lifecycle = [[GameLifecycle alloc] init];
    
    NSString* gameid;
    if ((gameid = [launchOptions valueForKey:@"gameid"]))
    {
        [lifecycle processNotification:launchOptions];
    }
    else
    {
        // TODO: check for other launch options?
        
        // load new game scene if there isnt one currently going
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCurrentGameIDKey];
        NSString* gameID = [[NSUserDefaults standardUserDefaults] valueForKey:kCurrentGameIDKey];

        if (gameID == nil) // do new game if no existing game
        {
            [lifecycle playNewGame]; // will set the gameID from there
        }
        else // lets load the game and play it
        {
            [lifecycle playNextRoundInGameWithID:gameID];
        }
    }
    return lifecycle;
}

+(void) deleteGameStateSave
{
    NSString* path = [CoreGameLayer SavegamePath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path])
    {
        NSError* error;
        [[NSFileManager defaultManager] removeItemAtPath:path error:(&error)];
        if (error != nil) ULog(@"%@", [error localizedDescription]);
    }
}

-(id) init
{
    if (self=[super init])
    {
        _serverApi = [DVAPIWrapper wrapper];
    }
    return self;
}

-(void) playNewGame
{
    CCScene* newGameScene = [NewGameLayer sceneWithBlockCalledOnNewGameClicked:^(id sender) {
        [_serverApi postCreateNewGameThenCallBlock:^(NSError *error, DVServerGameData *status) {
            if (error != nil)
            {
                ULog(@"%@", [error localizedDescription]);
            }
            else
            {
                DLog(@"Saving gameID to defaults: %@", status.gameID);
                [[NSUserDefaults standardUserDefaults] setObject:status.gameID forKey:kCurrentGameIDKey];
                
                // In this case, we are the HOST of the new game, so we get playerID = 1, GUEST will get 2
                CCScene* gameScene = [CoreGameLayer sceneWithInitType:NewGameAsHost];
                _gameLayer = (CoreGameLayer *)[gameScene getChildByTag:kCoreGameLayerTag];
                
                [[CCDirector sharedDirector] replaceScene:gameScene];
                
                // start our turn
                CountdownLayer* cdlayer = [[CountdownLayer alloc]
                                           initWithCountdownFrom:kCountDownFrom
                                           AndCallBlockWhenCountdownFinished:
                                           ^(id status) {
                                               [_gameLayer startRound];
                                           }];
                
                [gameScene addChild:cdlayer];
                
                // get notified when the round is done
                [[NSNotificationCenter defaultCenter] addObserver:self
                                                         selector:@selector(roundHasFinished:)
                                                             name:kCoreGameRoundFinishedNotification
                                                           object:_gameLayer];
            }
        }];
    }];
    [[CCDirector sharedDirector] pushScene:newGameScene];

}

// TODO: add passed param to play a specific game ID for multiple game handling, now only assuming 1
-(void) playNextRoundInGameWithID:(NSString *)gameID
{
    [[CCDirector sharedDirector] pushScene:[LoadingLayer scene]];

    [_serverApi getGameStatusForID:gameID
                     ThenCallBlock:
     ^(NSError *error, DVServerGameData *status)
    {
        if (error != nil)
        {
            ULog(@"%@", [error localizedDescription]);
        }
        else
        {
            DLog(@"Sucessfully got status for gameID: %@", status.gameID);
            NSString* deviceToken = [[NSUserDefaults standardUserDefaults] valueForKey:kDeviceToken];
            if ([status.nextTurn isEqualToString:deviceToken]) // my turn
            {
                // load last scene
                DLog(@"Loading CoreGame from savegame '%@'", [CoreGameLayer SavegamePath]);

                CCScene* gameScene;
                if ([[NSUserDefaults standardUserDefaults] valueForKey:kCurrentGameIDKey])
                {
                    gameScene = [CoreGameLayer sceneWithInitType:LoadSavedGame];
                }
                else // we havent saved the gameID so must be first round of GUEST game
                {
                    // TODO: make it more transparent why it is we are calling a newGameAsGuest here
                    [[NSUserDefaults standardUserDefaults] setValue:gameID forKey:kCurrentGameIDKey];
                    gameScene = [CoreGameLayer sceneWithInitType:NewGameAsGuest];
                }

                _gameLayer = (CoreGameLayer *)[gameScene getChildByTag:kCoreGameLayerTag];
                [[CCDirector sharedDirector] replaceScene:gameScene];

                // setup callback for our turn async
                [[NSNotificationCenter defaultCenter] addObserverForName:kCoreGamePlaybackFinishedNotification
                                                                  object:_gameLayer
                                                                   queue:nil
                                                              usingBlock:
                                                             ^(NSNotification *note)
                                                              {
                                                                  [_gameLayer setViewpointCenter:_gameLayer.player.sprite.position];
                                                                  CountdownLayer* cdlayer = [[CountdownLayer alloc]
                                                                                             initWithCountdownFrom:kCountDownFrom
                                                                                             AndCallBlockWhenCountdownFinished:
                                                                     ^(id status) {
                                                                         [_gameLayer startRound];
                                                                     }];
                                                                  [gameScene addChild:cdlayer];
                                                              }];
                // playback opponents turn
                [_gameLayer playbackEvents:status.updates];
                
                [[NSNotificationCenter defaultCenter] addObserver:self
                                                         selector:@selector(roundHasFinished:)
                                                             name:kCoreGameRoundFinishedNotification
                                                           object:_gameLayer];
            }
            else // still waiting for opponents turn
                [[CCDirector sharedDirector] pushScene:[AwaitingMoveLayer scene]];
        }
    }];
}

-(void) roundHasFinished:(NSNotification *) notification
{
    [_gameLayer saveGameState]; // CHECK maybe this should be done after posting was successful ??
    
    // TODO: remove, this is only for debug
//    NSString *urlString = [NSString stringWithFormat:@"%@/game/%@/fakeupdate",
//                           kBaseURL,
//                           [[NSUserDefaults standardUserDefaults] valueForKey:kCurrentGameIDKey]];
    
//    [_serverApi postToURL:urlString
//             UpdateEvents:[EntityNode CompleteEventHistory]
//       WithGameOverStatus:[_gameLayer getGameOverStatus]
//            ThenCallBlock:^(NSError *error)
    [_serverApi postUpdateEvents:[EntityNode CompleteEventHistory]
              WithGameOverStatus:[_gameLayer getGameOverStatus]
                   ThenCallBlock:
     ^(NSError *error)
    {
        if (error != nil)
        {
            ULog(@"%@", [error localizedDescription]);
        }
        else
        {
            [EntityNode ResetEventHistory];
            [[CCDirector sharedDirector] replaceScene:[AwaitingMoveLayer scene]];
        }
    }];
}

-(void) processNotification:(NSDictionary *) notificationInfo
{
    NSString* gameID;
    if ((gameID = [notificationInfo objectForKey:@"gameid"]))
    {
        DLog(@"Notification received for gameID: %@", gameID);
        
        // fake initial guest turn
//        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCurrentGameIDKey];
//        [GameLifecycle deleteGameStateSave];
        
        // TODO: check if we are already playing, this should be a different check in the future for multiple games
        if ([[NSUserDefaults standardUserDefaults]valueForKey:kCurrentGameIDKey] == nil)
        {
            // TODO: add game acceptance layer
        }
        [self playNextRoundInGameWithID:gameID];
    }
    else NSAssert(false, @"didnt receive gameid in notification payload");
}

-(void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end