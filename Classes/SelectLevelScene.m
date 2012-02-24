//
//  SelectLevelScene.m
//  Skeleton Key HD
//
//  Created by micah on 1/3/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SelectLevelScene.h"
#import "SkeletonKeyHDAppDelegate.h"
#import "MenuScene.h"
#import "GameScene.h"

@implementation SelectLevelScene

@synthesize stage;

+ (id) scene {
	CCScene* scene = [CCScene node];
	SelectLevelScene* layer = [SelectLevelScene node];
	[scene addChild:layer];
	return scene;
}

- (id) init {
	if((self=[super init])) {
		NSLog(@"SelectLevelScene init");
		
		self.isTouchEnabled = YES;
		levelToLoad = -1;
		levelLoading = FALSE;
		sound = ((SkeletonKeyHDAppDelegate*)([UIApplication sharedApplication].delegate)).sound;
		levels = ((SkeletonKeyHDAppDelegate*)([UIApplication sharedApplication].delegate)).levels;
		gameData = ((SkeletonKeyHDAppDelegate*)([UIApplication sharedApplication].delegate)).gameData;
		options = ((SkeletonKeyHDAppDelegate*)([UIApplication sharedApplication].delegate)).options;
		
		// background
		CCSprite* background;
		switch(gameData.stage) {
			case GameStageForest:
				background = [CCSprite spriteWithFile:@"select_level_background_forest.png"];
				break;
			case GameStageCaves:
				background = [CCSprite spriteWithFile:@"select_level_background_caves.png"];
				break;
			case GameStageBeach:
				background = [CCSprite spriteWithFile:@"select_level_background_beach.png"];
				break;
			case GameStageShip:
				background = [CCSprite spriteWithFile:@"select_level_background_ship.png"];
				break;
		}
		background.position = ccp(384, 512);
		[self addChild:background];
		
		// header
		CCSprite* header = [CCSprite spriteWithFile:@"select_level_header.png"];
		header.position = ccp(473.5, 950);
		[self addChild:header z:2];
		
		// back menu
		CCMenuItemImage* backItem = [CCMenuItemImage itemFromNormalImage:@"select_level_back.png" 
														   selectedImage:@"select_level_back2.png" 
																  target:self selector:@selector(onBack:)];
		CCMenu* backMenu = [CCMenu menuWithItems:backItem, nil];
		[backMenu alignItemsHorizontallyWithPadding:0];
		backMenu.position = ccp(89, 950);
		[self addChild:backMenu z:2];
		
		// easy, medium, hard buttons
		easy = [CCSprite spriteWithFile:@"select_level_easy.png"];
		easy.position = ccp(155.5, 53);
		[self addChild:easy z:2];
		medium = [CCSprite spriteWithFile:@"select_level_medium.png"];
		medium.position = ccp(384, 53);
		[self addChild:medium z:2];
		hard = [CCSprite spriteWithFile:@"select_level_hard.png"];
		hard.position = ccp(612.5, 53);
		[self addChild:hard z:2];
		
		// display the level numbers
		startingLevel = 0;
		switch(gameData.stage) {
			case GameStageForest: startingLevel = 1; break;
			case GameStageCaves: startingLevel = 31; break;
			case GameStageBeach: startingLevel = 61; break;
			case GameStageShip: startingLevel = 91; break;
		}
		float x = 111, y = 811.5;
		for(int i=startingLevel; i<startingLevel+30; i++) {
			Level* level = [levels.levels objectAtIndex:i-1];
			CCLabelTTF* num = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"%i",i] 
												 fontName:@"deutsch.ttf" fontSize:65];
			num.position = ccp(x, y);
			[self addChild:num z:2 tag:SelectLevelTagNums+i];
			
			// display stars for perfect levels
			if(level.perfect) {
				CCSprite* perfect = [CCSprite spriteWithFile:@"select_level_perfect.png"];
				perfect.position = ccp(x+44, y+42);
				[self addChild:perfect z:3];
			}
			
			// update coordinates
			x += 136;
			if(x > 655) {
				x = 111;
				y -= 129;
			}
		}
		[self updateDifficulty];
	}
	return self;
}

- (void) onBack:(id)sender {
	NSLog(@"SelectLevelScene onBack");
	[sound playClick];
	if(gameData.returnToGame) {
        [gameData loadGame];
        [[CCDirector sharedDirector] replaceScene:[CCTransitionPageTurn transitionWithDuration:0.3 scene:[GameScene scene] backwards:YES]];
    } else {
        [[CCDirector sharedDirector] replaceScene:[CCTransitionPageTurn transitionWithDuration:0.3 scene:[MenuScene scene] backwards:YES]];
    }
}

- (void) updateDifficulty {
	switch(options.difficulty) {
		case GameDifficultyEasy:
			easy.opacity = 255;
			medium.opacity = 64;
			hard.opacity = 64;
			break;
		case GameDifficultyMedium:
			easy.opacity = 64;
			medium.opacity = 255;
			hard.opacity = 64;
			break;
		case GameDifficultyHard:
			easy.opacity = 64;
			medium.opacity = 64;
			hard.opacity = 255;
			break;
	}
	
	for(int i=startingLevel; i<startingLevel+30; i++) {
		Level* level = (Level*)[levels.levels objectAtIndex:i-1];
		CCLabelTTF* num = (CCLabelTTF*)[self getChildByTag:SelectLevelTagNums+i];
		
		BOOL dimm = TRUE;
		switch(options.difficulty) {
			case GameDifficultyEasy:
				if(level.complete_easy) dimm = FALSE;
				break;
			case GameDifficultyMedium:
				if(level.complete_medium) dimm = FALSE;
				break;
			case GameDifficultyHard:
				if(level.complete_hard) dimm = FALSE;
				break;
		}
		if(dimm) {
			num.opacity = 64;
		} else {
            num.opacity = 255;
        }
	}
}

- (void) registerWithTouchDispatcher {
	[[CCTouchDispatcher sharedDispatcher] addTargetedDelegate:self priority:0 swallowsTouches:YES];
}

- (BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event {
	touchStart = [self convertTouchToNodeSpace:touch];
    return YES;
}

- (void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event {
	CGPoint touchEnd = [self convertTouchToNodeSpace:touch];
	float x = touchEnd.x;
	float y = touchEnd.y;
	
	// check difficulty
	if(y < 107) {
		// easy
		if(x < 267) {
			options.difficulty = GameDifficultyEasy;
			NSLog(@"SelectLevelScene changed difficulty to easy");
		}
		// medium
		else if(x >= 267 && x < 502) {
			options.difficulty = GameDifficultyMedium;
			NSLog(@"SelectLevelScene changed difficulty to medium");
		}
		// hard
		else {
			options.difficulty = GameDifficultyHard;
			NSLog(@"SelectLevelScene changed difficulty to hard");
		}
		
		// save settings
		[sound playClick];
		[options save];
		[self updateDifficulty];
		return;
	}
	
	// check levels
	if(y >= 107 && y < 875 && x >= 43 && x < 726) {
		// see which level is selected
		int levelX = (int)((x-43)/136);
		int levelY = (int)((y-107)/129);
		int level = (5*(5-levelY))+levelX+startingLevel;
		NSLog(@"SelectLevelScene touched level %i", level);
		
		// highlight the label
		CCLabelTTF* num = (CCLabelTTF*)[self getChildByTag:50+level];
		num.color = ccc3(255, 196, 0);
		num.opacity = 255;
		
		// trigger the load level event
		[sound playClick];
		levelToLoad = level;
		[self runAction:[CCSequence actions:
						 [CCDelayTime actionWithDuration:0.2f], 
						 [CCCallFunc actionWithTarget:self selector:@selector(loadLevel:)], 
						 nil]];
		return;
	}
}

- (void) loadLevel:(id)sender {
	if(levelLoading) return;
	levelLoading = TRUE;
	
	// change music
	[sound startMusicGameplay];
	
	// load level, start game
	gameData.level = levelToLoad;
	[gameData loadLevel];
	[[CCDirector sharedDirector] replaceScene:[CCTransitionFade transitionWithDuration:0.5 scene:[GameScene scene]]];
}

- (void) dealloc {
	NSLog(@"SelectLevelScene dealloc");
	[super dealloc];
}

@end
