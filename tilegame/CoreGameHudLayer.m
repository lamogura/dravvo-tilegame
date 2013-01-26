//
//  CoreGameHud.m
//  tilegame
//
//  Created by mogura on 1/26/13.
//
//

#import "CoreGameHudLayer.h"
#import "GameConstants.h"

@implementation CoreGameHudLayer

@synthesize gameLayer = _gameLayer;

-(id) init
{
    if((self = [super init]))
    {        
        // setup a mode menu item
        CCMenuItem* on;
        CCMenuItem* off;
        
        on = [CCMenuItemImage itemWithNormalImage:@"projectile-button-on.png"
                                    selectedImage:@"projectile-button-on.png"];
        off = [CCMenuItemImage itemWithNormalImage:@"projectile-button-off.png"
                                     selectedImage:@"projectile-button-off.png"];
        
        CCMenuItemToggle *toggleItem = [CCMenuItemToggle itemWithTarget:self
                                                               selector:@selector(projectileButtonTapped:)
                                                                  items:off, on, nil];
        CCMenu *toggleMenu = [CCMenu menuWithItems:toggleItem, nil];
        toggleMenu.position = ccp(100, 32);
        [self addChild:toggleMenu];  // add the toggle menu to the HUD layer
        
        
        CGSize winSize = [[CCDirector sharedDirector] winSize];
        
        // initialize label for melons collected count
        _labelMelonsCount = [CCLabelTTF labelWithString:@"melons: 0"
                                             dimensions:CGSizeMake(350, 20)
                                             hAlignment:UITextAlignmentRight
                                               fontName:@"Verdana-Bold"
                                               fontSize:18.0];
        _labelMelonsCount.color = ccc3(0, 0, 0);
        int margin = 10;
        _labelMelonsCount.position = ccp(winSize.width - (_labelMelonsCount.contentSize.width/2) - margin,
                                         _labelMelonsCount.contentSize.height/2 + margin);
        [self addChild:_labelMelonsCount];
        
        // initialize label for kill count
        _labelKillsCount = [CCLabelTTF labelWithString:@"kills: 0"
                                            dimensions:CGSizeMake(350, 20)
                                            hAlignment:UITextAlignmentRight
                                              fontName:@"Verdana-Bold"
                                              fontSize:18.0];
        _labelKillsCount.color = ccc3(255, 0, 0);
        margin = 10;
        _labelKillsCount.position = ccp(winSize.width - (_labelKillsCount.contentSize.width/2) - margin,
                                        _labelKillsCount.contentSize.height/2 + margin*2 + _labelMelonsCount.contentSize.height/2);
        [self addChild:_labelKillsCount];
        
        // label for numShurikens
        _labelShurikensCount = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"S: %d", kInitShurikens]
                                                dimensions:CGSizeMake(100, 20)
                                                hAlignment:UITextAlignmentRight
                                                  fontName:@"Verdana-Bold"
                                                  fontSize:18.0];
        _labelShurikensCount.color = ccc3(67, 173, 59);
        margin = 10;
        _labelShurikensCount.position = ccp(winSize.width - (_labelShurikensCount.contentSize.width/2) - margin,
                                            winSize.height - _labelShurikensCount.contentSize.height/2 - margin);
        [self addChild:_labelShurikensCount];
        
        // label for numMissiles
        _labelMissilesCount = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"M: %d", kInitMissiles]
                                               dimensions:CGSizeMake(100, 20)
                                               hAlignment:UITextAlignmentRight
                                                 fontName:@"Verdana-Bold"
                                                 fontSize:18.0];
        _labelMissilesCount.color = ccc3(0, 0, 255);
        margin = 10;
        _labelMissilesCount.position = ccp(winSize.width - (_labelMissilesCount.contentSize.width/2) - margin*2 - (_labelShurikensCount.contentSize.width/2),
                                           winSize.height - _labelMissilesCount.contentSize.height/2 - margin);
        [self addChild:_labelMissilesCount];
        
        // label for T-minus time remaining in this round
        _labelTimer = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Time: %d", kTurnLengthSeconds]
                                       dimensions:CGSizeMake(350, 20)
                                       hAlignment:UITextAlignmentLeft
                                         fontName:@"Verdana-Bold"
                                         fontSize:18.0];
        _labelTimer.color = ccc3(255, 0, 0);
        margin = 10;
        _labelTimer.position = ccp((_labelTimer.contentSize.width/2) + margin,
                                  winSize.height - _labelTimer.contentSize.height/2 - margin);
        [self addChild:_labelTimer];
    }
    return self;
}

-(void) projectileButtonTapped:(id)sender
{
    _gameLayer.mode = _gameLayer.mode == 1 ? 0 : 1;
}

-(void) numCollectedChanged:(int)numCollected
{
    [_labelMelonsCount setString:[NSString stringWithFormat:@"melons: %d", numCollected]];
}

-(void) numKillsChanged:(int) numKills
{
    [_labelKillsCount setString:[NSString stringWithFormat:@"kills: %d", numKills]];
}

-(void) numShurikensChanged:(int) numShurikens
{
    [_labelShurikensCount setString:[NSString stringWithFormat:@"S: %d", numShurikens]];
}

-(void) numMissilesChanged:(int) numMissiles
{
    [_labelMissilesCount setString:[NSString stringWithFormat:@"M: %d", numMissiles]];
}

-(void) timerChanged:(int) newTime
{
    [_labelTimer setString:[NSString stringWithFormat:@"Time: %d", newTime]];
}

@end

