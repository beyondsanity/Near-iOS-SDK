//
//  NITConfiguration.m
//  NearITSDK
//
//  Created by Francesco Leoni on 14/03/17.
//  Copyright © 2017 NearIT. All rights reserved.
//

#import "NITConfiguration.h"
#import "NITUtils.h"

#define APIKEY @"apikey"
#define APPID @"appid"
#define PROFILE_ID @"profileId"
#define INSTALLATIONID @"installationid"
#define DEVICETOKEN @"devicetoken"

static NSString *const defaultConfigurationLock = @"configuration.lock";
static NITConfiguration *defaultConfiguration;

@interface NITConfiguration()

@property (nonatomic, strong) NSString * _Nonnull apiKey;
@property (nonatomic, strong) NSString * _Nonnull appId;
@property (nonatomic, strong) NSString * _Nonnull profileId;
@property (nonatomic, strong) NSString * _Nullable installationId;
@property (nonatomic, strong) NSString * _Nullable deviceToken;
@property (nonatomic, strong) NSArray<NSString*> *keys;
@property (nonatomic, strong) NSUserDefaults *userDefaults;
@property (nonatomic, strong) NSUserDefaults *suiteUserDefaults;

@end

@implementation NITConfiguration

@synthesize apiKey = _apiKey;
@synthesize appId = _appId;
@synthesize profileId = _profileId;
@synthesize installationId = _installationId;
@synthesize deviceToken = _deviceToken;
@synthesize suiteUserDefaults = _suiteUserDefaults;

+ (NITConfiguration*)defaultConfiguration {
    @synchronized (defaultConfigurationLock) {
        if (defaultConfiguration == nil) {
            defaultConfiguration = [[NITConfiguration alloc] init];
        }
    }
    return defaultConfiguration;
}

- (instancetype)init {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [self initWithUserDefaults:userDefaults];
}

- (instancetype)initWithUserDefaults:(NSUserDefaults*)userDefaults {
    self = [super init];
    if (self) {
        self.keys = @[APIKEY, APPID, PROFILE_ID, INSTALLATIONID, DEVICETOKEN];
        self.userDefaults = userDefaults;
        NSString *apiKey = [userDefaults objectForKey:APIKEY];
        NSString *profileId = [userDefaults objectForKey:PROFILE_ID];
        NSString *installationId = [userDefaults objectForKey:INSTALLATIONID];
        if (apiKey) {
            self.apiKey = apiKey;
        }
        if (profileId) {
            self.profileId = profileId;
        }
        if (installationId) {
            self.installationId = installationId;
        }
    }
    return self;
}

- (NSString*)paramKeyWithKey:(NSString*)key {
    if (_appId) {
        NSString *param = [key stringByAppendingString:[NSString stringWithFormat:@"-%@", _appId]];
        return param;
    }
    return nil;
}

- (NSString *)apiKey {
    if (_apiKey == nil) {
        _apiKey = [self objectWithKey:APIKEY];
    }
    return _apiKey;
}

- (void)setApiKey:(NSString * _Nonnull)apiKey {
    _apiKey = apiKey;
    _appId = [NITUtils fetchAppIdFromApiKey:apiKey];
    if ([_appId length] == 0) {
        NSLog(@"[ERROR] - NearIT SDK malformed or invalid Api Key");
    }
    [self saveParamWithKey:APIKEY value:apiKey];
    [self saveParamWithKey:APPID value:_appId];
}

- (NSString *)appId {
    if (_appId == nil) {
        _appId = [self objectWithKey:APPID];
    }
    return _appId;
}

- (void)setAppId:(NSString * _Nonnull)appId {
    _appId = appId;
    [self saveParamWithKey:APPID value:appId];
}

- (NSString *)profileId {
    if(_profileId == nil) {
        _profileId = [self objectWithKey:PROFILE_ID];
    }
    return _profileId;
}

- (void)setProfileId:(NSString *)profileId {
    _profileId = profileId;
    if (profileId) {
        [self saveParamWithKey:PROFILE_ID value:profileId];
    } else {
        [self.userDefaults removeObjectForKey:[self paramKeyWithKey:PROFILE_ID]];
    }
}

- (NSString *)installationId {
    if(_installationId == nil) {
        _installationId = [self objectWithKey:INSTALLATIONID];
    }
    return _installationId;
}

- (void)setInstallationId:(NSString *)installationId {
    _installationId = installationId;
    if (installationId) {
        [self saveParamWithKey:INSTALLATIONID value:installationId];
    } else {
        [self.userDefaults removeObjectForKey:[self paramKeyWithKey:INSTALLATIONID]];
    }
}

- (NSString *)deviceToken {
    if(_deviceToken == nil) {
        _deviceToken = [self objectWithKey:DEVICETOKEN];
    }
    return _deviceToken;
}

- (void)setDeviceToken:(NSString *)deviceToken {
    _deviceToken = deviceToken;
    [self saveParamWithKey:DEVICETOKEN value:DEVICETOKEN];
}

- (void)saveParamWithKey:(NSString*)key value:(id)object {
    NSString *realKey = [self paramKeyWithKey:key];
    if (realKey) {
        [self.userDefaults setObject:object forKey:realKey];
        [self.userDefaults synchronize];
        [self.suiteUserDefaults setObject:object forKey:key];
        [self.suiteUserDefaults synchronize];
    }
}

- (id)objectWithKey:(NSString*)key {
    NSString *realKey = [self paramKeyWithKey:key];
    if (realKey) {
        return [self.userDefaults objectForKey:realKey];
    }
    return nil;
}

- (void)clear {
    for (NSString *key in self.keys) {
        NSString *realKey = [self paramKeyWithKey:key];
        if (realKey) {
            [self.userDefaults removeObjectForKey:realKey];
            [self.suiteUserDefaults removeObjectForKey:key];
        }
    }
    [self.userDefaults synchronize];
    _apiKey = nil;
    _appId = nil;
    _profileId = nil;
    _installationId = nil;
    _deviceToken = nil;
}

@end
