//
//  NewGameScene.m
//  tutorial_TileGame
//
//  Created by Justin Kovalchuk on 1/12/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "NewGameLayer.h"
#import "CoreGameLayer.h"
#import "DVMacros.h"
#import "DVConstants.h"

@implementation NewGameLayer

-(id) init
{
    if( (self=[super initWithColor:ccc4(255,255,255,255)] )) {
        self->_apiWrapper = [[DVAPIWrapper alloc] init];
        CCMenuItemImage *newGameItem = [CCMenuItemImage
                                        itemWithNormalImage:@"new_game_button.png"
                                        selectedImage:nil
                                        disabledImage:nil
                                        block:^(id sender) {
            [self->_apiWrapper postCreateNewGameThenCallBlock:^(NSError *error, DVServerGameData *status) {
                if (error != nil) {
                    ULog([error localizedDescription]);
                }
                else {
                    DLog(@"Saving gameID to defaults: %@", status.gameID);
                    [[NSUserDefaults standardUserDefaults] setObject:status.gameID forKey:kCurrentGameIDKey];
                    // TODO: add logic where new game is generated locally
                    
                    // In this case, we are the HOST of the new game, so we get playerID = 1, GUEST will get 2
                    ////[CoreGameLayer setPlayerID:1];
                    
                    [[CCDirector sharedDirector] replaceScene:[CoreGameLayer scene:DVNewGameAsHost]];
                }
            }];
        }];
        
        CCMenu *menu= [CCMenu menuWithItems:newGameItem, nil];
        //Aligning & Adding CCMenu child to the scene
        [menu alignItemsVertically];
        [self addChild:menu];
    }
    return self;
}

- (void) dealloc {
    self->_apiWrapper = nil;
}

+(CCScene *) scene
{
	CCScene *scene = [CCScene node];
	[scene addChild: [NewGameLayer node]];
	return scene;
}

@end