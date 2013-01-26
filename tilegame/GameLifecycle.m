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
+(void) startWithDirector:(CCDirectorIOS *)director {
    // load new game scene if there isnt one currently going

    NSString* currentGameID = nil;//[[NSUserDefaults standardUserDefaults] valueForKey:kCurrentGameIDKey];
    if (currentGameID != nil) {
        DLog(@"Found gameID: %@", currentGameID);
        [director pushScene: [CoreGameLayer scene]];
        //        [director_ pushScene: [HelloWorldLayer scene]];
    }
    else {
        [director pushScene: [NewGameLayer scene]];
    }
}
@end
