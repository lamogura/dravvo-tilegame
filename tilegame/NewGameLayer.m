//
//  NewGameScene.m
//  tutorial_TileGame
//
//  Created by Jeremiah Anderson on 1/12/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "NewGameLayer.h"
#import "HelloWorldLayer.h"
#import "DVMacros.h"
#import "DVConstants.h"

@implementation NewGameScene
@synthesize layer = _layer;

-(id) init
{
    if((self = [super init]))
    {
        self.layer = [NewGameLayer node];
        [self addChild:_layer];
    }
    return self;
}

@end

@implementation NewGameLayer

-(id) init
{
    if( (self=[super initWithColor:ccc4(255,255,255,255)] )) {
        self->_apiWrapper = [[DVAPIWrapper alloc] init];
        
        CCMenuItemImage *item1 = [CCMenuItemImage itemWithNormalImage:@"new_game_button.png" selectedImage:nil disabledImage:nil block:^(id sender) {
            [self->_apiWrapper postCreateNewGameThenCallBlock:^(NSError *error, DVGameStatus *status) {
                if (error != nil) {
                    ULog([error localizedDescription]);
                }
                else {
                    DLog(@"Saving gameID to defaults: %@", status.gameID);
                    [[NSUserDefaults standardUserDefaults] setObject:status.gameID forKey:kCurrentGameIDKey];
                }
            }];
            [[CCDirector sharedDirector] replaceScene:[HelloWorldLayer scene]];
        }];
        
        //Adding menu items to the CCMenu. Don't forget to include 'nil'
        CCMenu *selectMenu= [CCMenu menuWithItems:item1, nil];
        //Aligning & Adding CCMenu child to the scene
        [selectMenu alignItemsVertically];
        [self addChild:selectMenu];
    }
    return self;
}

- (void) dealloc {
    self->_apiWrapper = nil;
}

+(CCScene *) scene
{
	CCScene *theScene = [CCScene node];
    NewGameLayer *layer = [NewGameLayer node];

	[theScene addChild: layer];
	return theScene;
}

@end