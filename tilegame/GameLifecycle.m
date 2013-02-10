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

@implementation GameLifecycle

+(void) deleteGameStateSave
{
    NSString* path = [CoreGameLayer gameStateFilePath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:path])
    {
        NSError* error;
        [[NSFileManager defaultManager] removeItemAtPath:path error:(&error)];
        if (error != nil) ULog(@"%@", [error localizedDescription]);
    }
}

+(void) startWithDirector:(CCDirectorIOS *)director {
    // load new game scene if there isnt one currently going

//    if (currentGameID != nil) {
//        DLog(@"Found gameID: %@", currentGameID);
    
//    [GameLifecycle deleteGameStateSave];
//
    [director pushScene: [CoreGameLayer scene:DVLoadFromFile]];  // FIX replace with  [director pushScene:
//    [director pushScene: [CoreGameLayer scene:DVNewGameAsHost]];  // FIX replace with  [director pushScene:

//    }
//    else {
//        [director pushScene: [NewGameLayer scene]];
//    }
    
}
@end
