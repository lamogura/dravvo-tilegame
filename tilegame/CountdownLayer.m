//
//  NewGameScene.m
//  tutorial_TileGame
//
//  Created by Justin Kovalchuk on 1/12/13.
//  Copyright (c) 2013 __MyCompanyName__. All rights reserved.
//

#import "CountdownLayer.h"
#import "HelloWorldLayer.h"
#import "DVMacros.h"
#import "DVConstants.h"

@implementation CountdownLayer
@synthesize countdownCount = _countdownCount;
@synthesize label = _label;

-(id) init
{
    if( (self=[super initWithColor:ccc4(255,255,255,0)] )) {
        self.countdownCount = kCountdownFrom;
        self.label = [CCLabelTTF labelWithString:[NSString stringWithFormat:kLabelFormat, self.countdownCount] fontName:@"Arial" fontSize:58];
        
        CGSize winSize = [[CCDirector sharedDirector] winSize];
        self.label.color = ccc3(0,0,0);
        self.label.position = ccp(winSize.width/2, winSize.height/2);
        
        [self addChild:self.label];
        [self schedule:@selector(updateLabel:) interval:1];
//        id scaleUpAction = [CCEaseInOut actionWithAction:[CCScaleTo actionWithDuration:1 scaleX:3.0 scaleY:3.0] rate:1.0];
    }
    return self;
}

-(void) updateLabel:(ccTime) delta {
    if (--self.countdownCount <= 0) {
        [self unschedule:_cmd];
        [self.parent removeChild:self cleanup:YES];
    }
    self.label.string = [NSString stringWithFormat:kLabelFormat, self.countdownCount];
}

+(CCScene *) scene
{
	CCScene *scene = [CCScene node];
	[scene addChild: [CountdownLayer node]];
	return scene;
}

@end