//
//  GameLifecycle.m
//  tilegame
//
//  Created by mogura on 1/26/13.
//
//

#import "cocos2d.h"
#import "GameLifecycle.h"
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
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kUserDefaultsKey_GameID];
        NSString* gameID = [[NSUserDefaults standardUserDefaults] valueForKey:kUserDefaultsKey_GameID];

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

+(void) deleteSaveGame:(NSString *)saveGamePath
{
    if ([[NSFileManager defaultManager] fileExistsAtPath:saveGamePath])
    {
        NSError* error;
        [[NSFileManager defaultManager] removeItemAtPath:saveGamePath error:(&error)];
        if (error != nil)
            ULog(@"%@", [error localizedDescription]);
    }
}

-(void) playNewGame
{
    NSString* deviceToken = [[NSUserDefaults standardUserDefaults] valueForKey:kUserDefaultsKey_DeviceToken];
    
    CCScene* newGameScene = [NewGameLayer sceneWithBlockCalledOnNewGameClicked:^(id sender)
    {
        [[DVAPIWrapper staticWrapper] createNewGameForDeviceToken:deviceToken
                                                    callbackBlock:^(NSError *error, DVServerGameData *status)
        {
            if (error != nil)
            {
                ULog(@"%@", [error localizedDescription]);
            }
            else
            {
                DLog(@"Saving gameID to defaults: %@", status.gameID);
                [[NSUserDefaults standardUserDefaults] setObject:status.gameID forKey:kUserDefaultsKey_GameID];

                // In this case, we are the HOST of the new game, so we get playerID = 1, GUEST will get 2
                CCScene* gameScene = [CoreGameLayer sceneNewGameForPlayerRole:PlayerRole_Host];
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

-(void) roundHasFinished:(NSNotification *) notification
{
    NSString* gameID = [[NSUserDefaults standardUserDefaults] valueForKey:kUserDefaultsKey_GameID];
    NSString* deviceToken = [[NSUserDefaults standardUserDefaults] valueForKey:kUserDefaultsKey_DeviceToken];

#if LONELY_DEBUG
    NSFileManager* fileMgr = [NSFileManager defaultManager];
    NSString* lastTurnSavePath = [CoreGameLayer saveGamePathOfLastPlayersTurn];
    NSString* nextTurnSavePath = [CoreGameLayer saveGamePath];

    // swap save games so next time we will be resuming from other players turn
    if ([fileMgr fileExistsAtPath:lastTurnSavePath]) // every round after 1
    {
        [GameLifecycle deleteSaveGame:nextTurnSavePath]; // if exists
        NSError* error;
        [fileMgr moveItemAtPath:lastTurnSavePath
                         toPath:nextTurnSavePath
                          error:&error];
        if (error != nil)
            ULog(@"%@", [error localizedDescription]);
    }
    else // first round so also remove gameID since guest player wouldnt have it
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kUserDefaultsKey_GameID];
    
    [_gameLayer saveGameStateToPath:lastTurnSavePath];
#else
    // CHECK maybe this should be done after posting was successful ??
    [_gameLayer saveGameStateToPath:[CoreGameLayer saveGamePath]];
#endif

    
    [[DVAPIWrapper staticWrapper] postGameUpdates:[EntityNode sharedEventHistory]
                                   gameOverStatus:[_gameLayer getGameOverStatus]
                                        forGameID:gameID
                                      deviceToken:deviceToken
                                    callbackBlock:^(NSError *error)
     {
         if (error != nil)
         {
             ULog(@"%@", [error localizedDescription]);
         }
         else
         {
             [EntityNode clearEventHistory];
             [[CCDirector sharedDirector] replaceScene:[AwaitingMoveLayer scene]];
         }
     }];
}

// TODO: add passed param to play a specific game ID for multiple game handling, now only assuming 1
-(void) playNextRoundInGameWithID:(NSString *)gameID
{
    [[CCDirector sharedDirector] pushScene:[LoadingLayer scene]];

    [[DVAPIWrapper staticWrapper] getGameStatusForID:gameID
                                       callbackBlock:^(NSError *error, DVServerGameData *status)
    {
        if (error != nil)
        {
            ULog(@"%@", [error localizedDescription]);
        }
        else
        {
            DLog(@"Sucessfully got status for gameID: %@", status.gameID);
            NSString* deviceToken = [[NSUserDefaults standardUserDefaults] valueForKey:kUserDefaultsKey_DeviceToken];
            if ([status.nextTurn isEqualToString:deviceToken]) // my turn
            {
                // load last scene
                DLog(@"Loading CoreGame from savegame '%@'", [CoreGameLayer saveGamePath]);

                CCScene* gameScene;
                if ([[NSUserDefaults standardUserDefaults] valueForKey:kUserDefaultsKey_GameID])
                {
                    gameScene = [CoreGameLayer sceneWithGameFromSavedGame:[CoreGameLayer saveGamePath]];
                }
                else // we havent saved the gameID so must be first round of GUEST game
                {
                    // TODO: make it more transparent why it is we are calling a newGameAsGuest here
                    [[NSUserDefaults standardUserDefaults] setValue:gameID forKey:kUserDefaultsKey_GameID];
                    gameScene = [CoreGameLayer sceneNewGameForPlayerRole:PlayerRole_Guest];
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
        if ([[NSUserDefaults standardUserDefaults]valueForKey:kUserDefaultsKey_GameID] == nil)
        {
            // TODO: add game acceptance layer
        }
        [self playNextRoundInGameWithID:gameID];
    }
    else
        ULog(@"didnt receive gameid in notification info");
}

-(void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end