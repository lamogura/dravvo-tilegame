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
#import "AwaitingOpponentMoveScene.h"

@implementation GameLifecycle

+(void) start
{
    CCDirector* director = [CCDirector sharedDirector];
    DVAPIWrapper* apiWrapper = [[DVAPIWrapper alloc] init];
    
    // load new game scene if there isnt one currently going
//    [[NSUserDefaults standardUserDefaults] removeObjectForKey:kCurrentGameIDKey];
    NSString* gameID = [[NSUserDefaults standardUserDefaults] valueForKey:kCurrentGameIDKey];
    
    if (gameID == nil)
    {
        [director pushScene:[NewGameLayer scene]];
    }
    else
    {
        [director pushScene:[LoadingLayer scene]];
        
        [apiWrapper getGameStatusThenCallBlock:^(NSError *error, DVServerGameData *status) {
            //TODO: update game with the game status
            if (error != nil)
            {
                ULog(@"%@", [error localizedDescription]);
            }
            else
            {
                DLog(@"Sucessfully got status for gameID: %@", status.gameID);
                NSString* deviceToken = [[NSUserDefaults standardUserDefaults] valueForKey:kDeviceToken];
                if ([status.nextTurn isEqualToString:deviceToken])
                {
                    // load last scene
                    DLog(@"Loading CoreGame from savegame '%@'", [CoreGameLayer SavegamePath]);
                    CCScene* gameScene = [CoreGameLayer scene:ReloadReplay];
                    CoreGameLayer* gameLayer = (CoreGameLayer *)[gameScene getChildByTag:13];
                    [director pushScene:gameScene];
                    
                    // TODO show replay of opponent
                    
                    // start our turn
                    CountdownLayer* cdlayer = [[CountdownLayer alloc] initWithCountdownFrom:3 AndCallBlockWhenCountdownFinished:^(id status) {
                        [gameLayer startRound];
                    }];
                    [gameScene addChild:cdlayer];
                }
                else [director pushScene:[AwaitingOpponentMoveLayer scene]];
            }
        }];
    }
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

@end