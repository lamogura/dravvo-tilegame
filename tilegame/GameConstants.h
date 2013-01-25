//
//  gameConstants.h
//  dravvo-tilegame_master
//
//  Created by Jeremiah Anderson on 1/21/13.
//
//

// dictionary keys for the historicalEventsList
#define kTimeStepIndex @"TimeStepIndex"
#define kAction @"Action"
#define kEntityType @"EntityType"
#define kEntityNumber @"EntityNumber"
#define kCoordX @"CoordX"
#define kCoordY @"CoordY"


#define kTickLengthSeconds 0.10  // length of a single tick in seconds (time between mainGameLoop callbacks)
#define kPlaybackTickLengthSeconds 0.5  // sampling rate and playback rate
#define kTurnLengthSeconds 10  // length of a players entire turn in seconds, before passing to next player's turn

// List of different enumerated AI behaviors, each defined uniquely within entity's method definitions
#define kBehavior_default 0    // entity will take its default actions
#define kBehavior_idle 1    // entity will take no actions
#define kBehavior_attackOpponent 2  // entity will attack opponent
#define kBehavior_attackPlayer 3    // entity will attack player
#define kBehavior_random 4  // entity will take random actions

#define kNumMelons 5
#define kInitShurikens 10
#define kInitMissiles 10
#define kMaxMelons 5
//#define kTimeStepSeconds 1  // time step for sampling rate and oponnent turn re-play animation rate