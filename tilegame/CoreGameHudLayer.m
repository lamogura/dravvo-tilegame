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

-(id) initWithCoreGameLayer:(CoreGameLayer *)layer
{
    if((self = [super init]))
    {        
        // setup shuriken toggle button
        CCMenuItem* on = [CCMenuItemImage itemWithNormalImage:@"projectile-button-on.png"
                                                selectedImage:@"projectile-button-on.png"];
        CCMenuItem* off = [CCMenuItemImage itemWithNormalImage:@"projectile-button-off.png"
                                                 selectedImage:@"projectile-button-off.png"];
        CCMenuItemToggle* itemToggle = [CCMenuItemToggle
                                        itemWithItems:[NSArray arrayWithObjects:off, on, nil]
                                        block:^(id sender) {
                                            layer.playerMode = layer.playerMode == DVPlayerMode_Moving ? DVPlayerMode_Shooting : DVPlayerMode_Moving;
                                        }];
        CCMenu *toggleMenu = [CCMenu menuWithItems:itemToggle, nil];
        toggleMenu.position = ccp(100, 32);
        
        [self addChild:toggleMenu];  // add the toggle menu to the HUD layer
        
        // init all the labels and setup KVO
        CGSize winSize = [[CCDirector sharedDirector] winSize];

        // melsons
        _labelMelons = [CCLabelTTF labelWithString:[NSString stringWithFormat:kHUDStringFormat_Melons, layer.numCollected]
                                        dimensions:CGSizeMake(350, 20)
                                        hAlignment:UITextAlignmentRight
                                          fontName:@"Verdana-Bold"
                                          fontSize:18.0];
        [layer addObserver:self forKeyPath:kDVNumMelonsKVO options:NSKeyValueObservingOptionNew context:nil];
        _labelMelons.color = ccc3(0, 0, 0);
        int margin = 10;
        _labelMelons.position = ccp(winSize.width - (_labelMelons.contentSize.width/2) - margin,
                                    _labelMelons.contentSize.height/2 + margin);
        [self addChild:_labelMelons];
        
        // kills
        _labelKills = [CCLabelTTF labelWithString:[NSString stringWithFormat:kHUDStringFormat_Kills, layer.numKills]
                                       dimensions:CGSizeMake(350, 20)
                                       hAlignment:UITextAlignmentRight
                                         fontName:@"Verdana-Bold"
                                         fontSize:18.0];
        [layer addObserver:self forKeyPath:kDVNumKillsKVO options:NSKeyValueObservingOptionNew context:nil];
        _labelKills.color = ccc3(255, 0, 0);
        margin = 10;
        _labelKills.position = ccp(winSize.width - (_labelKills.contentSize.width/2) - margin,
                                   _labelKills.contentSize.height/2 + margin*2 + _labelKills.contentSize.height/2);
        [self addChild:_labelKills];
        
        // shurikens
        _labelShurikens = [CCLabelTTF labelWithString:[NSString stringWithFormat:kHUDStringFormat_Shurikens, layer.numShurikens]
                                           dimensions:CGSizeMake(100, 20)
                                           hAlignment:UITextAlignmentRight
                                             fontName:@"Verdana-Bold"
                                             fontSize:18.0];
        [layer addObserver:self forKeyPath:kDVNumShurikensKVO options:NSKeyValueObservingOptionNew context:nil];
        _labelShurikens.color = ccc3(67, 173, 59);
        margin = 10;
        _labelShurikens.position = ccp(winSize.width - (_labelShurikens.contentSize.width/2) - margin,
                                       winSize.height - _labelShurikens.contentSize.height/2 - margin);
        [self addChild:_labelShurikens];
        
        // missles
        _labelMissiles = [CCLabelTTF labelWithString:[NSString stringWithFormat:kHUDStringFormat_Missles, layer.numMissiles]
                                          dimensions:CGSizeMake(100, 20)
                                          hAlignment:UITextAlignmentRight
                                            fontName:@"Verdana-Bold"
                                            fontSize:18.0];
        [layer addObserver:self forKeyPath:kDVNumMisslesKVO options:NSKeyValueObservingOptionNew context:nil];
        _labelMissiles.color = ccc3(0, 0, 255);
        margin = 10;
        _labelMissiles.position = ccp(winSize.width - (_labelMissiles.contentSize.width/2) - margin*2 - (_labelMissiles.contentSize.width/2),
                                      winSize.height - _labelMissiles.contentSize.height/2 - margin);
        [self addChild:_labelMissiles];
        
        // timer
        _labelTimer = [CCLabelTTF labelWithString:[NSString stringWithFormat:kHUDStringFormat_Timer, (int)layer.timer]
                                       dimensions:CGSizeMake(350, 20)
                                       hAlignment:UITextAlignmentLeft
                                         fontName:@"Verdana-Bold"
                                         fontSize:18.0];
        [layer addObserver:self forKeyPath:kDVNumTimerKVO options:NSKeyValueObservingOptionNew context:nil];
        _labelTimer.color = ccc3(255, 0, 0);
        margin = 10;
        _labelTimer.position = ccp((_labelTimer.contentSize.width/2) + margin,
                                   winSize.height - _labelTimer.contentSize.height/2 - margin);
        [self addChild:_labelTimer];
    }
    return self;
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:kDVNumMelonsKVO]) {
        [_labelMelons setString:[NSString stringWithFormat:kHUDStringFormat_Melons, [[change objectForKey:NSKeyValueChangeNewKey] intValue]]];
    }
    else if ([keyPath isEqualToString:kDVNumKillsKVO]) {
        [_labelKills setString:[NSString stringWithFormat:kHUDStringFormat_Kills, [[change objectForKey:NSKeyValueChangeNewKey] intValue]]];
    }
    else if ([keyPath isEqualToString:kDVNumMisslesKVO]) {
        [_labelMissiles setString:[NSString stringWithFormat:kHUDStringFormat_Missles, [[change objectForKey:NSKeyValueChangeNewKey] intValue]]];
    }
    else if ([keyPath isEqualToString:kDVNumShurikensKVO]) {
        [_labelShurikens setString:[NSString stringWithFormat:kHUDStringFormat_Shurikens, [[change objectForKey:NSKeyValueChangeNewKey] intValue]]];
    }
    else if ([keyPath isEqualToString:kDVNumTimerKVO]) {
        [_labelTimer setString:[NSString stringWithFormat:kHUDStringFormat_Timer, (int)[[change objectForKey:NSKeyValueChangeNewKey] floatValue]]];
    }
}

@end

