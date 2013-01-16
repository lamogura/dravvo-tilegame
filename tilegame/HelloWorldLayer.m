//
//  HelloWorldLayer.m
//  tutorial_TileGame
//
//  Created by Jeremiah Anderson on 12/10/12.
//  Copyright __MyCompanyName__ 2012. All rights reserved.
//
// SEE: http://www.raywenderlich.com/1163/how-to-make-a-tile-based-game-with-cocos2d

// Import the interfaces
#import "HelloWorldLayer.h"

// Needed to obtain the Navigation Controller
#import "AppDelegate.h"
#import "SimpleAudioEngine.h"
#import "DVMacros.h"
#import "DVConstants.h"

@implementation HelloWorldHud

@synthesize gameLayer = _gameLayer;

-(id) init
{
    if((self = [super init]))
    {
        // setup a mode menu item
        CCMenuItem* on;
        CCMenuItem* off;
        on = [[CCMenuItemImage itemFromNormalImage:@"projectile-button-on.png"
                                     selectedImage:@"projectile-button-on.png" target:nil selector:nil] retain];
        off = [[CCMenuItemImage itemFromNormalImage:@"projectile-button-off.png"
                                      selectedImage:@"projectile-button-off.png" target:nil selector:nil] retain];
        CCMenuItemToggle *toggleItem = [CCMenuItemToggle itemWithTarget:self
                                                               selector:@selector(projectileButtonTapped:) 
                                                                  items:off, on, nil];
        CCMenu *toggleMenu = [CCMenu menuWithItems:toggleItem, nil];
        toggleMenu.position = ccp(100, 32);
        [self addChild:toggleMenu];  // add the toggle menu to the HUD layer
        
        
        CGSize winSize = [[CCDirector sharedDirector] winSize];
        label = [CCLabelTTF labelWithString:@"0" dimensions:CGSizeMake(50, 20) alignment:UITextAlignmentRight fontName:@"Verdana-Bold" fontSize:18.0];
        label.color = ccc3(0, 0, 0);
        int margin = 10;
        label.position = ccp(winSize.width - (label.contentSize.width/2) 
                             - margin, label.contentSize.height/2 + margin);
        [self addChild:label];
    }
    return self;
}

-(void) projectileButtonTapped:(id)sender
{
    if(_gameLayer.mode == 1)
        _gameLayer.mode = 0;
    else
        _gameLayer.mode = 1;
}

-(void) numCollectedChanged:(int)numCollected
{
    [label setString:[NSString stringWithFormat:@"%d", numCollected]];
}

@end



#pragma mark - HelloWorldLayer

// HelloWorldLayer implementation
@implementation HelloWorldLayer

@synthesize tileMap = _tileMap;
@synthesize background = _background;
@synthesize meta = _meta;
@synthesize foreground = _foreground;
@synthesize player = _player;
@synthesize numCollected = _numCollected;
@synthesize hud = _hud;
@synthesize mode = _mode;

// Helper class method that creates a Scene with the HelloWorldLayer as the only child.
// What calls this class??
+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *theScene = [CCScene node];
	
	// 'layer' is an autorelease object.
	HelloWorldLayer *layer = [HelloWorldLayer node];
	
	// add layer as a child to scene
	[theScene addChild: layer];
    
    // create and add the HUD label/stats layer!
    HelloWorldHud* hud = [HelloWorldHud node];
    [theScene addChild:hud];
    
    layer.hud = hud;  // store a member var reference to the hud so we can refer back to it to reset the label strings!
    hud.gameLayer = layer;  // 2-way references
	
	// return the scene
	return theScene;
}

// on "init" you need to initialize your instance
-(id) init
{
	// always call "super" init
	// Apple recommends to re-assign "self" with the "super's" return value
	if( (self=[super init]) ) {
        
        DLog(@"");
        DLog(@"TESTING API WRAPPER");
        DLog(@"*******************");
        
        self->apiWrapper = [[DVAPIWrapper alloc] init];
        
        // test create new game
//        [self->apiWrapper postCreateNewGameThenCallBlock:^(NSError *error, DVGameStatus *status) {
//            if (error != nil) {
//                ULog([error localizedDescription]);
//            }
//            else {
//                [[NSUserDefaults standardUserDefaults] setObject:[status gameID] forKey:kCurrentGameIDKey];
//                DLog(@"CREATED NEW GAME, saved GameID '%@'to NSUserDefaults", [status gameID]);
//            }
//        }];
        
        // test getting current game's status
//        [self->apiWrapper getGameStatusThenCallBlock:^(NSError *error, DVGameStatus *status) {
//            if (error != nil) {
//                ULog([error localizedDescription]);
//            }
//            else {
//                DLog(@"GOT GAME STATUS");
//            }
//        }];
        
        // test sending game update
//        NSDictionary* updates = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:5], @"melonsEaten", [NSNumber numberWithInt:2], @"enemiesKilled", [NSNumber numberWithInt:6], @"starsThrown", @"false", kIsGameOver, nil];
//        [self->apiWrapper postUpdateGameWithUpdates:updates ThenCallBlock:^(NSError* error) {
//            if (error != nil) {
//                ULog([error localizedDescription]);
//            }
//            else {
//                DLog(@"UPDATED GAME GAME STATUS");
//            }
//        }];
        
        self.isTouchEnabled = YES;  // set THIS LAYER as touch enabled so user can move character around with callbacks
		
        _mode = 0;  // default game mode = 0, move mode (mode = 1, shoot mode)
        
        _enemies = [[NSMutableArray alloc] init];
        _projectiles = [[NSMutableArray alloc] init];
        [self schedule:@selector(testCollisions:)];
        
        // sound effects pre-load
        [[SimpleAudioEngine sharedEngine] preloadEffect:@"pickup.caf"];
        [[SimpleAudioEngine sharedEngine] preloadEffect:@"hit.caf"];
        [[SimpleAudioEngine sharedEngine] preloadEffect:@"move.caf"];
        [[SimpleAudioEngine sharedEngine] playBackgroundMusic:@"TileMap.caf"];
        
        // load the TileMap and the tile layers
        self.tileMap = [CCTMXTiledMap tiledMapWithTMXFile:@"TileMap.tmx"];
        self.background = [_tileMap layerNamed:@"Background"];
        self.meta = [_tileMap layerNamed:@"Meta"];
        self.foreground = [_tileMap layerNamed:@"Foreground"];
        _meta.visible = NO;
        
        // get the objectGroup objects layer from the tileMap, it contains spawn point objects for player and enemy sprites
        CCTMXObjectGroup* objects = [_tileMap objectGroupNamed:@"Objects"];
        NSAssert(objects != nil, @"'Objects' object group not found");
        
        // extract the "SpawnPoint" object from the tileMap object
        NSMutableDictionary* spawnPoint = [objects objectNamed:@"SpawnPoint"];        
        NSAssert(spawnPoint != nil, @"SpawnPoint object not found");
        int x = [[spawnPoint valueForKey:@"x"] intValue];
        int y = [[spawnPoint valueForKey:@"y"] intValue];
        
        // draw the player sprite
        self.player = [CCSprite spriteWithFile:@"Player.png"];
        _player.position = ccp(x, y);
        [self addChild:_player];
        
        // draw the enemy sprites
        // iterate through tileMap dictionary objects, finding all enemy spawn points
        // create an enemy for each one
//        NSMutableDictionary* spawnPoint;

        // objects method returns an array of objects (in this case dictionaries) from the ObjectGroup
        for(spawnPoint in [objects objects]) 
        {
            if([[spawnPoint valueForKey:@"Enemy"] intValue] == 1)
            {
                x = [[spawnPoint valueForKey:@"x"] intValue];
                y = [[spawnPoint valueForKey:@"y"] intValue];
                [self addEnemyAtX:x y:y];
            }
        }
        
        // set the view position focused on player
        [self setViewpointCenter:_player.position];
        
        [self addChild:_tileMap z:-1];
        
    }
	return self;
}

- (void) setViewpointCenter:(CGPoint) position
{
    CGSize winSize = [[CCDirector sharedDirector] winSize];
    
    int x = MAX(position.x, winSize.width/2);
    int y = MAX(position.y, winSize.height/2);
    x = MIN(x, (_tileMap.mapSize.width * _tileMap.tileSize.width) - winSize.width/2);
    y = MIN(y, (_tileMap.mapSize.height * _tileMap.tileSize.height) - winSize.height/2);
    CGPoint actualPosition = ccp(x, y);
    
    CGPoint centerOfView = ccp(winSize.width/2, winSize.height/2);
    CGPoint viewPoint = ccpSub(centerOfView, actualPosition);
    self.position = viewPoint;
}

// registering ourself as the as the listener for touch events, meaning ccTouchBegan and ccTouchEnded will be called back
-(void) registerWithTouchDispatcher
{
    [[CCTouchDispatcher sharedDispatcher] addTargetedDelegate:self priority:0 swallowsTouches:YES];
}

-(BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    return YES;
}

-(void) setPlayerPosition:(CGPoint) position
{
    CGPoint tileCoord = [self tileCoordForPosition:position];
    int tileGid = [_meta tileGIDAt:tileCoord];  // GID is the ID for this kind of tile
    if(tileGid)
    {
        NSDictionary* properties = [_tileMap propertiesForGID:tileGid];
        // 
        if(properties)
        {
            // IS this tile a "collidable" tile?
            // if the target move tile is collidable, then simply return and don't set player position to the target
            NSString* collision = [properties valueForKey:@"Collidable"];
            if(collision && [collision compare:@"True"] == NSOrderedSame)
            {
                // ran into a wall sound
                [[SimpleAudioEngine sharedEngine] playEffect:@"hit.caf"];
                return;
            }
            // IS this tile a "collectable" tile?
            NSString *collectable = [properties valueForKey:@"Collectable"];
            if (collectable && [collectable compare:@"True"] == NSOrderedSame)
            {
                // got the item sound
                [[SimpleAudioEngine sharedEngine] playEffect:@"pickup.caf"];
                // removing from both meta layer AND foreground means we can no longer see OR "collect" the item
                [_meta removeTileAt:tileCoord];  
                [_foreground removeTileAt:tileCoord];
                self.numCollected++;
                [_hud numCollectedChanged:_numCollected];
            }
        }
    }
    
    _player.position = position;
}

-(void) ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
    // if move mode
    if(_mode == 0)
    {
        CGPoint touchLocation = [touch locationInView: [touch view]];		
        touchLocation = [[CCDirector sharedDirector] convertToGL: touchLocation];
        touchLocation = [self convertToNodeSpace:touchLocation];
        // calling convertToNodeSpace method offsets the touch based on how we have moved the layer
        // for example, This is because the touch location will give us coordinates for where the user tapped inside the viewport (for example 100,100). But we might have scrolled the map a good bit so that it actually matches up to (800,800) for example.
    
        // this just moves sprite by the one tile of pixels
        CGPoint playerPos = _player.position;
        CGPoint diff = ccpSub(touchLocation, playerPos);
        if (abs(diff.x) > abs(diff.y)) {
            if (diff.x > 0) {
                playerPos.x += _tileMap.tileSize.width;
            } else {
                playerPos.x -= _tileMap.tileSize.width; 
            }    
        } else {
            if (diff.y > 0) {
                playerPos.y += _tileMap.tileSize.height;
            } else {
                playerPos.y -= _tileMap.tileSize.height;
            }
        }
    
        if (playerPos.x <= (_tileMap.mapSize.width * _tileMap.tileSize.width) &&
            playerPos.y <= (_tileMap.mapSize.height * _tileMap.tileSize.height) &&
            playerPos.y >= 0 &&
            playerPos.x >= 0 ) 
        {
            // moved the player sound
            [[SimpleAudioEngine sharedEngine] playEffect:@"move.caf"];
            [self setPlayerPosition:playerPos];
        }
    
        [self setViewpointCenter:_player.position];
    }
    // else if throw shuriken mode
    else {
        // Find where the touch point is
        CGPoint touchLocation = [touch locationInView:[touch view]];
        touchLocation = [[CCDirector sharedDirector] convertToGL:touchLocation];
        touchLocation = [self convertToNodeSpace:touchLocation];
        
        // Create a projectile and put it at the player's location
        CCSprite* projectile = [CCSprite spriteWithFile:@"Projectile.png"];
        projectile.position = _player.position;
        [self addChild:projectile];
        
        // Determine where we want to shoot the projectile to
        int realX;
        
        // Are we shooting to the left or right?
        CGPoint diff = ccpSub(touchLocation, _player.position);
        if(diff.x > 0)
            realX = (_tileMap.mapSize.width * _tileMap.tileSize.width) + (projectile.contentSize.width/2);
        else
            realX = -(_tileMap.mapSize.width * _tileMap.tileSize.width) - (projectile.contentSize.width/2);
        
        float ratio = (float) diff.y / (float) diff.x;
        int realY = ((realX - projectile.position.x) * ratio) + projectile.position.y;
        CGPoint realDest = ccp(realX, realY);
        
        // Determine the length of how far we're shooting
        int offRealX = realX - projectile.position.x;
        int offRealY = realY - projectile.position.y;
        float length = sqrtf((offRealX*offRealX) + (offRealY*offRealY));
        float velocity = 480/1; // 480pixels/1sec
        float realMoveDuration = length/velocity;
        
        // Move projectile to actual endpoint
        id actionMoveDone = [CCCallFuncN actionWithTarget:self selector:@selector(projectileMoveFinished:)];
        [projectile runAction:[CCSequence actionOne:
                               [CCMoveTo actionWithDuration:realMoveDuration position:realDest]
                                                two:actionMoveDone]];
        // we need to keep a reference to each shuriken so we can delete it if it makes a collision with a target
        [_projectiles addObject:projectile];
    }
    
}

// there are iOS coordinates coresponding to the pixels starting with 0,0 at BOTTOM left corner...
// then there are tile index coordinates starting from 0,0 at TOP left corner
// we will need the tile coordinate for some purposes:
-(CGPoint) tileCoordForPosition:(CGPoint) position
{
    int x = position.x / _tileMap.tileSize.width;
    // gotta flip in y-direction
    int y = ((_tileMap.mapSize.height * _tileMap.tileSize.height) - position.y) / _tileMap.tileSize.height;
    return ccp(x,y);
}

-(void) addEnemyAtX:(int)x y:(int)y
{
    CCSprite* enemy = [CCSprite spriteWithFile:@"enemy1.png"];
    enemy.position = ccp(x, y);
    [self addChild:enemy];
    
    // Use our animation method and start the enemy moving toward the player
    [self animateEnemy:enemy];
    [_enemies addObject:enemy];
}

-(void) animateEnemy:(CCSprite*) enemy
{
    //immediately before creating the actions in animateEnemy
    //rotate to face the player
    CGPoint diff = ccpSub(_player.position, enemy.position);
    float angleRadians = atanf((float)diff.y / (float)diff.x);
    float angleDegrees = CC_RADIANS_TO_DEGREES(angleRadians);
    float cocosAngle = -1 * angleDegrees;
    if(diff.x < 0)
        cocosAngle += 180;
    enemy.rotation = cocosAngle;
    
    // speed of the enemy
    ccTime actualDuration = 0.3;
    
    // create the actions
    // ccpMult, ccpSub multiplies, subtracts two point coordinates (vectors) to give one resulting point
    // ccpNormalize calculates a unit vector given 2 point coordinates,...
    // and gives a hypotenous of length 1 with appropriate x,y
    id actionMove = [CCMoveBy actionWithDuration:actualDuration position:ccpMult(ccpNormalize(ccpSub(_player.position,enemy.position)), 10)];
    id actionMoveDone = [CCCallFuncN actionWithTarget:self selector:@selector(enemyMoveFinished:)];
    [enemy runAction:[CCSequence actions:actionMove, actionMoveDone, nil]];
}


// callback that starts another iteration of enemy movement.
// we know which sprite called us here because sender is a CCSprite - the sprite that just finished animating
-(void) enemyMoveFinished:(id)sender    
{
    CCSprite* enemy = (CCSprite*) sender;
    
    [self animateEnemy: enemy];
}

-(void) projectileMoveFinished:(id) sender
{
    CCSprite* sprite = (CCSprite*) sender;
    [self removeChild:sprite cleanup:YES];
    
    [_projectiles removeObject:sprite];  // remove our reference to this shuriken from the projectiles array of sprite objects
}

-(void) testCollisions:(ccTime) dt
{
    NSMutableArray* projectilesToDelete = [[NSMutableArray alloc] init];
    
    for (CCSprite *projectile in _projectiles) {
        CGRect projectileRect = CGRectMake(
                                           projectile.position.x - (projectile.contentSize.width/2),
                                           projectile.position.y - (projectile.contentSize.height/2),
                                           projectile.contentSize.width,
                                           projectile.contentSize.height);
        
        NSMutableArray *targetsToDelete = [[NSMutableArray alloc] init];
        
        // iterate through enemies, see if any intersect with current projectile
        for (CCSprite *target in _enemies) {
            CGRect targetRect = CGRectMake(
                                           target.position.x - (target.contentSize.width/2),
                                           target.position.y - (target.contentSize.height/2),
                                           target.contentSize.width,
                                           target.contentSize.height);
            
            if (CGRectIntersectsRect(projectileRect, targetRect)) {
                [targetsToDelete addObject:target];
            }
        }
        
        // delete all hit enemies
        for (CCSprite *target in targetsToDelete) {
            [_enemies removeObject:target];
            [self removeChild:target cleanup:YES];
        }
        
        if (targetsToDelete.count > 0) {
            // add the projectile to the list of ones to remove
            [projectilesToDelete addObject:projectile];
        }
        [targetsToDelete release];
    }
    
    // remove all the projectiles that hit.
    for (CCSprite *projectile in projectilesToDelete) {
        [_projectiles removeObject:projectile];
        [self removeChild:projectile cleanup:YES];
    }
    [projectilesToDelete release];
}

// on "dealloc" you need to release all your retained objects
- (void) dealloc
{
	// in case you have something to dealloc, do it in this method
	// in this particular example nothing needs to be released.
	// cocos2d will automatically release all the children (Label)
	
	// don't forget to call "super dealloc"
    self.tileMap = nil;
    self.background = nil;
    self.meta = nil;
    self.foreground = nil;
    self.player = nil;
    self.hud = nil;
	[super dealloc];
}

#pragma mark GameKit delegate

-(void) achievementViewControllerDidFinish:(GKAchievementViewController *)viewController
{
	AppController *app = (AppController*) [[UIApplication sharedApplication] delegate];
	[[app navController] dismissModalViewControllerAnimated:YES];
}

-(void) leaderboardViewControllerDidFinish:(GKLeaderboardViewController *)viewController
{
	AppController *app = (AppController*) [[UIApplication sharedApplication] delegate];
	[[app navController] dismissModalViewControllerAnimated:YES];
}
@end
