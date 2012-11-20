//
//  UnityAdsDevice.m
//  UnityAds
//
//  Created by bluesun on 10/19/12.
//  Copyright (c) 2012 Unity Technologies. All rights reserved.
//

#include <sys/socket.h>
#include <sys/sysctl.h>
#include <net/if.h>
#include <net/if_dl.h>
#include <CommonCrypto/CommonDigest.h>

#import <SystemConfiguration/SystemConfiguration.h>

#import "UnityAdsDevice.h"
#import "../UnityAds.h"
#import "../UnityAdsOpenUDID/UnityAdsOpenUDID.h"

NSString * const kUnityAdsDeviceIphone = @"iphone";
NSString * const kUnityAdsDeviceIphone3g = @"iphone3g";
NSString * const kUnityAdsDeviceIphone3gs = @"iphone3gs";
NSString * const kUnityAdsDeviceIphone4 = @"iphone4";
NSString * const kUnityAdsDeviceIphone4s = @"iphone4s";
NSString * const kUnityAdsDeviceIphone5 = @"iphone5";
NSString * const kUnityAdsDeviceIpodTouch1gen = @"ipodtouch1gen";
NSString * const kUnityAdsDeviceIpodTouch2gen = @"ipodtouch2gen";
NSString * const kUnityAdsDeviceIpodTouch3gen = @"ipodtouch3gen";
NSString * const kUnityAdsDeviceIpodTouch4gen = @"ipodtouch4gen";
NSString * const kUnityAdsDeviceIpad1 = @"ipad1";
NSString * const kUnityAdsDeviceIpad2 = @"ipad2";
NSString * const kUnityAdsDeviceIpad3 = @"ipad3";
NSString * const kUnityAdsDeviceIosUnknown = @"iosUnknown";

@implementation UnityAdsDevice

+ (NSString *)_substringOfString:(NSString *)string toIndex:(NSInteger)index
{
	if (index > [string length])
	{
		UALOG_DEBUG(@"Index %d out of bounds for string '%@', length %d.", index, string, [string length]);
		return nil;
	}
	
	return [string substringToIndex:index];
}

+ (NSString *)advertisingIdentifier
{
	NSString *identifier = nil;
	
	Class advertisingManagerClass = NSClassFromString(@"ASIdentifierManager");
	if ([advertisingManagerClass respondsToSelector:@selector(sharedManager)])
	{
		id advertisingManager = [[advertisingManagerClass class] performSelector:@selector(sharedManager)];
		BOOL enabled = YES; // Not sure what to do with this value.
    
		if ([advertisingManager respondsToSelector:@selector(isAdvertisingTrackingEnabled)])
		{
			NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[advertisingManagerClass instanceMethodSignatureForSelector:@selector(isAdvertisingTrackingEnabled)]];
			[invocation setSelector:@selector(isAdvertisingTrackingEnabled)];
			[invocation setTarget:advertisingManager];
			[invocation invoke];
			[invocation getReturnValue:&enabled];
		}
		
		//UALOG_DEBUG(@"Ad tracking %@.", enabled ? @"enabled" : @"disabled");
    
		if ([advertisingManager respondsToSelector:@selector(advertisingIdentifier)])
		{
			id advertisingIdentifier = [advertisingManager performSelector:@selector(advertisingIdentifier)];
			if (advertisingIdentifier != nil && [advertisingIdentifier respondsToSelector:@selector(UUIDString)])
			{
				id uuid = [advertisingIdentifier performSelector:@selector(UUIDString)];
				if ([uuid isKindOfClass:[NSString class]])
					identifier = uuid;
			}
		}
	}
	
	return identifier;
}

+ (BOOL)canUseTracking
{
  Class advertisingManagerClass = NSClassFromString(@"ASIdentifierManager");
	if ([advertisingManagerClass respondsToSelector:@selector(sharedManager)])
	{
		id advertisingManager = [[advertisingManagerClass class] performSelector:@selector(sharedManager)];
		BOOL enabled = YES; // Not sure what to do with this value.
    
		if ([advertisingManager respondsToSelector:@selector(isAdvertisingTrackingEnabled)])
		{
			NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[advertisingManagerClass instanceMethodSignatureForSelector:@selector(isAdvertisingTrackingEnabled)]];
			[invocation setSelector:@selector(isAdvertisingTrackingEnabled)];
			[invocation setTarget:advertisingManager];
			[invocation invoke];
			[invocation getReturnValue:&enabled];
      
      return enabled;
		}
  }
  
  return YES;
}

+ (NSString *)machineName
{
	size_t size;
  sysctlbyname("hw.machine", NULL, &size, NULL, 0);
  char *answer = malloc(size);
	sysctlbyname("hw.machine", answer, &size, NULL, 0);
	NSString *result = [NSString stringWithCString:answer encoding:NSUTF8StringEncoding];
	free(answer);
	
	return result;
}

+ (NSString *)analyticsMachineName {
	NSString *machine = [self machineName];
	if ([machine isEqualToString:@"iPhone1,1"])
		return kUnityAdsDeviceIphone;
	else if ([machine isEqualToString:@"iPhone1,2"])
		return kUnityAdsDeviceIphone3g;
	else if ([machine isEqualToString:@"iPhone2,1"])
		return kUnityAdsDeviceIphone3gs;
	else if ([machine length] > 6 && [[self _substringOfString:machine toIndex:7] isEqualToString:@"iPhone3"])
		return kUnityAdsDeviceIphone4;
	else if ([machine length] > 6 && [[self _substringOfString:machine toIndex:7] isEqualToString:@"iPhone4"])
		return kUnityAdsDeviceIphone4s;
	else if ([machine length] > 6 && [[self _substringOfString:machine toIndex:7] isEqualToString:@"iPhone5"])
		return kUnityAdsDeviceIphone5;
	else if ([machine isEqualToString:@"iPod1,1"])
		return kUnityAdsDeviceIpodTouch1gen;
	else if ([machine isEqualToString:@"iPod2,1"])
		return kUnityAdsDeviceIpodTouch2gen;
	else if ([machine isEqualToString:@"iPod3,1"])
		return kUnityAdsDeviceIpodTouch3gen;
	else if ([machine isEqualToString:@"iPod4,1"])
		return kUnityAdsDeviceIpodTouch4gen;
	else if ([machine length] > 4 && [[self _substringOfString:machine toIndex:5] isEqualToString:@"iPad1"])
		return kUnityAdsDeviceIpad1;
	else if ([machine length] > 4 && [[self _substringOfString:machine toIndex:5] isEqualToString:@"iPad2"])
		return kUnityAdsDeviceIpad2;
	else if ([machine length] > 4 && [[self _substringOfString:machine toIndex:5] isEqualToString:@"iPad3"])
		return kUnityAdsDeviceIpad3;
  
	return kUnityAdsDeviceIosUnknown;
}

+ (NSString *)_md5StringFromString:(NSString *)string {
	if (string == nil) {
		UALOG_DEBUG(@"Input is nil.");
		return nil;
	}
	
	const char *ptr = [string UTF8String];
	unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
	CC_MD5(ptr, strlen(ptr), md5Buffer);
	NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
	for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
		[output appendFormat:@"%02x",md5Buffer[i]];
	
	return output;
}

+ (NSString *)md5OpenUDIDString {
	return [UnityAdsDevice _md5StringFromString:[UnityAdsOpenUDID value]];
}

+ (NSString *)md5AdvertisingIdentifierString {
	NSString *adId = [self advertisingIdentifier];
	if (adId == nil) {
		UALOG_DEBUG(@"Advertising identifier not available.");
		return nil;
	}
	
	return [self _md5StringFromString:adId];
}

+ (NSString *)currentConnectionType {
	NSString *wifiString = @"wifi";
	NSString *cellularString = @"cellular";
	NSString *connectionString = nil;
	
	SCNetworkReachabilityRef reachabilityRef = SCNetworkReachabilityCreateWithName(NULL, "unity3d.com");
	if (reachabilityRef != NULL) {
		SCNetworkReachabilityFlags flags;
		if (SCNetworkReachabilityGetFlags(reachabilityRef, &flags)) {
			if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0) {
				// if target host is reachable and no connection is required
				//  then we'll assume (for now) that you're on Wi-Fi
				connectionString = wifiString;
			}
			
			if ((flags & kSCNetworkReachabilityFlagsConnectionOnDemand) != 0 || (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0)
			{
				// ... and the connection is on-demand (or on-traffic) if the
				//     calling application is using the CFSocketStream or higher APIs
				
				if ((flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0)
				{
					// ... and no [user] intervention is needed
					connectionString = wifiString;
				}
			}
			
			if ((flags & kSCNetworkReachabilityFlagsIsWWAN) != 0)
			{
				// ... but WWAN connections are OK if the calling application
				//     is using the CFNetwork (CFSocketStream?) APIs.
				connectionString = cellularString;
			}
      
			if ((flags & kSCNetworkReachabilityFlagsReachable) == 0)
			{
				// if target host is not reachable
				connectionString = nil;
			}
		}
    
		CFRelease(reachabilityRef);
	}
	
	return connectionString;
}

+ (NSString *)softwareVersion {
  return [[UIDevice currentDevice] systemVersion];
}

+ (NSString *)md5DeviceId {
  return [UnityAdsDevice md5AdvertisingIdentifierString] != nil ? [UnityAdsDevice md5AdvertisingIdentifierString] : [UnityAdsDevice md5OpenUDIDString];
}

+ (int)getIOSMajorVersion {
  
  return [[[self softwareVersion] substringToIndex:1] intValue];
}

+ (NSNumber *)getIOSExactVersion {
  NSNumberFormatter * f = [[NSNumberFormatter alloc] init];
  [f setNumberStyle:NSNumberFormatterDecimalStyle];
  NSNumber *myNumber = [f numberFromString:[self softwareVersion]];
  return myNumber;
}

@end