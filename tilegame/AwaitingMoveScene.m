//
//  AwaitingOpponentMoveScene.m
//  tilegame
//
//  Created by mogura on 2/10/13.
//
//

#import "AwaitingMoveScene.h"
#import "DVMacros.h"
#import "DVConstants.h"

@implementation AwaitingMoveLayer

-(id)init
{
    if( (self=[super initWithColor:ccc4(255,255,255,255)] )) {
        CCLabelTTF *label = [CCLabelTTF labelWithString:@"Waiting for Opponent to finish turn..."
                                               fontName:@"Arial"
                                               fontSize:26];
        label.color = ccc3(0,0,0);
        
        CCMenuItemImage *item = [CCMenuItemLabel itemWithLabel:label];
                             
        CCMenu *menu= [CCMenu menuWithItems:item, nil];
        
        [menu alignItemsVertically];
        [self addChild:menu];
    }
    return self;
}


+(CCScene *) scene
{
	CCScene *scene = [CCScene node];
	[scene addChild: [[AwaitingMoveLayer alloc] init]];
	return scene;
}

@end