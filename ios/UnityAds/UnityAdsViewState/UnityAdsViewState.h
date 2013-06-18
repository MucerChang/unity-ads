//
//  UnityAdsViewState.h
//  UnityAds
//
//  Created by Pekka Palmu on 4/4/13.
//  Copyright (c) 2013 Unity Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "../UnityAdsProperties/UnityAdsConstants.h"
#import "../UnityAds.h"
#import "../UnityAdsCampaign/UnityAdsCampaignManager.h"
#import "../UnityAdsCampaign/UnityAdsCampaign.h"
#import "../UnityAdsWebView/UnityAdsWebAppController.h"

@protocol UnityAdsViewStateDelegate <NSObject>

@required
- (void)stateNotification:(UnityAdsViewStateAction)action;
@end

@interface UnityAdsViewState : NSObject

@property (nonatomic, assign) id<UnityAdsViewStateDelegate> delegate;
@property (nonatomic, assign) BOOL waitingToBeShown;
@property (nonatomic, strong) UIViewController *storeController;

- (UnityAdsViewStateType)getStateType;

- (void)enterState:(NSDictionary *)options;
- (void)exitState:(NSDictionary *)options;

- (void)willBeShown;
- (void)wasShown;

- (void)applyOptions:(NSDictionary *)options;

- (void)preloadAppSheetWithId:(NSString *)iTunesId;
- (void)openAppStoreWithData:(NSDictionary *)data inViewController:(UIViewController *)targetViewController;
@end