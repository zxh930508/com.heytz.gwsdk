/********* gwsdkwrapper.m Cordova Plugin Implementation *******/

#import "gwsdk.h"
#import "GwsdkUtils.h"


@implementation gwsdk

@synthesize commandHolder;
@synthesize _deviceList;

NSString *_currentPairDeviceMacAddress;
NSInteger currentState;
bool _debug = true;
NSString *_uid, *_token, *_mac, *_remark, *_alias, *_productSecret;
NSString *_currentbindDeviceMac, *_currentBindDeviceProductKey;

NSArray *devices; //内存中的device列表。


CDVInvokedUrlCommand *listenerCommandHolder;
//更新本地配置信息，必须
CDVInvokedUrlCommand *writeCommandHolder;
//写入设备的callbackId
CDVInvokedUrlCommand *startDeviceListCommandHolder;
//获取设备列表的回调
CDVInvokedUrlCommand *getHardwareInfoCommandHolder;
//获取设备详细信息
/**
 *  控制状态枚举
 */
typedef NS_ENUM(NSInteger, GwsdkStateCode) {
    /**
      *  只配对设备
     */
            setDeviceOnboardingCode = 5,
    /**
    *  配对设备并且绑定设备
    */
            setDeviceOnboardingAndBindDeviceCode = 6,
    /**
    * 循环获取设备列表
    */
            getBoundDevicesCode = 7
};


- (void)pluginInitialize {
    NSString *gizwAppId = [[self.commandDelegate settings] objectForKey:@"gizwappid"];
    if (gizwAppId) {
        [GizWifiSDK startWithAppID:gizwAppId];
        self.gizwAppId = gizwAppId;
    }

}

/**
 *  初始化状态，设置appid
 *
 *  @param command <#command description#>
 */
- (void)init:(CDVInvokedUrlCommand *)command {
    if (!([GizWifiSDK sharedInstance].delegate)) {
        [GizWifiSDK sharedInstance].delegate = self;
    }
    devices = [GizWifiSDK sharedInstance].deviceList;
    _currentPairDeviceMacAddress = nil;
    self.commandHolder = command;
}





/**
 *  回调:获取ssid列表
 *
 */
- (void)wifiSDK:(GizWifiSDK *)wifiSDK didGetSSIDList:(NSError *)result ssidList:(NSArray *)ssidList {
    if (result.code == GIZ_SDK_SUCCESS) {
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:ssidList];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:commandHolder.callbackId];
    } else {
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDouble:result.code];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:commandHolder.callbackId];
    }
}
//-----------------------------------------------新版接口 16.08.30---------------------------------------------------------
/**
 *  cordova 配对设备上网
 *
 *  @param command [wifiSSID, wifiKey, mode, timeout, softAPSSIDPrefix, wifiGAgentType]
 */
- (void)setDeviceOnboarding:(CDVInvokedUrlCommand *)command {

    [self init:command];
    currentState = setDeviceOnboardingCode;
    /*
       把设备配置到局域网 wifi 上。设备处于 softap 模式时，模组会产生一个热点名称，手机 wifi 连接此热点后就可以配置了。如果是机智云提供的固件，模组热点名称前缀为"XPG-GAgent-"，密码为"123456789"。设备处于 airlink 模式时，手机随时都可以开始配置。但无论哪种配置方式，设备上线时，手机要连接到配置的局域网 wifi 上，才能够确认设备已配置成功。
       设备配置成功时，在回调中会返回设备 mac 地址。如果设备重置了，设备did可能要在设备搜索回调中才能获取。

       @param ssid 待配置的路由 SSID 名
       @param key 待配置的路由密码
       @param mode 配置模式，详细见 GizWifiConfigureMode 枚举定义
       @param softAPSSIDPrefix SoftAPMode 模式下 SoftAP 的 SSID 前缀或全名。默认前缀为：XPG-GAgent-，SDK 以此判断手机当前是否连上了设备的 SoftAP 热点。AirLink 模式时传 nil 即可
       @param timeout 配置的超时时间。SDK 默认执行的最小超时时间为30秒
       @param types 待配置的模组类型，是一个GizWifiGAgentType 枚举数组。若不指定则默认配置乐鑫模组。GizWifiGAgentType定义了 SDK 支持的所有模组类型
       @see 对应的回调接口：[GizWifiSDKDelegate wifiSDK:didSetDeviceOnboarding:device:]
       @see GizConfigureMode
       @see GizWifiGAgentType
     */
    if (_debug) {
        NSLog(@"ssid:%@,pwd:%@", command.arguments[0], command.arguments[1]);
    }
    NSString *ssid = [command.arguments objectAtIndex:0];
    NSString *pwd = [command.arguments objectAtIndex:1];
    NSString *mode = [command.arguments objectAtIndex:2];
    NSString *timeout = [command.arguments objectAtIndex:3];
    NSString *softAPSSIDPrefix = ([command.arguments objectAtIndex:4] == [NSNull null]) ? nil : command.arguments[4];
    NSArray *wifiAgentTypeArr = [command.arguments objectAtIndex:5];

    [[GizWifiSDK sharedInstance] setDeviceOnboarding:ssid
                                                 key:pwd
                                          configMode:[mode intValue]
                                    softAPSSIDPrefix:softAPSSIDPrefix
                                             timeout:[timeout intValue]
                                      wifiGAgentType:wifiAgentTypeArr];
}

/**
 *  cordova 配对上网，并且绑定这个设备
 *
 *  @param command ["appid","","ssid","pwd",uid,token,timeout,mode,softApssidPrefix,wifiGAgentType]
 */
- (void)setDeviceOnboardingAndBindDevice:(CDVInvokedUrlCommand *)command {

    [self init:command];
    currentState = setDeviceOnboardingAndBindDeviceCode;

    /*
          把设备配置到局域网 wifi 上。设备处于 softap 模式时，模组会产生一个热点名称，手机 wifi 连接此热点后就可以配置了。如果是机智云提供的固件，模组热点名称前缀为"XPG-GAgent-"，密码为"123456789"。设备处于 airlink 模式时，手机随时都可以开始配置。但无论哪种配置方式，设备上线时，手机要连接到配置的局域网 wifi 上，才能够确认设备已配置成功。
          设备配置成功时，在回调中会返回设备 mac 地址。如果设备重置了，设备did可能要在设备搜索回调中才能获取。

          @param ssid 待配置的路由 SSID 名
          @param key 待配置的路由密码
          @param mode 配置模式，详细见 GizWifiConfigureMode 枚举定义
          @param softAPSSIDPrefix SoftAPMode 模式下 SoftAP 的 SSID 前缀或全名。默认前缀为：XPG-GAgent-，SDK 以此判断手机当前是否连上了设备的 SoftAP 热点。AirLink 模式时传 nil 即可
          @param timeout 配置的超时时间。SDK 默认执行的最小超时时间为30秒
          @param types 待配置的模组类型，是一个GizWifiGAgentType 枚举数组。若不指定则默认配置乐鑫模组。GizWifiGAgentType定义了 SDK 支持的所有模组类型
          @see 对应的回调接口：[GizWifiSDKDelegate wifiSDK:didSetDeviceOnboarding:device:]
          @see GizConfigureMode
          @see GizWifiGAgentType
        */
    //新接口 8.31
    if (_debug) {
        NSLog(@"ssid:%@,pwd:%@ mode:%@ timeout:%@ uid:%@ token:%@ ",
                command.arguments[0],
                command.arguments[1],
                command.arguments[2],
                command.arguments[3],
                command.arguments[6],
                command.arguments[7]);
    }

    NSString *ssid = [command.arguments objectAtIndex:0];
    NSString *pwd = [command.arguments objectAtIndex:1];
    NSString *mode = [command.arguments objectAtIndex:2];
    NSString *timeout = [command.arguments objectAtIndex:3];
    NSString *softAPSSIDPrefix = ([command.arguments objectAtIndex:4] == [NSNull null]) ? nil : command.arguments[7];
    NSArray *wifiAgentTypeArr = [command.arguments objectAtIndex:5];
    _uid = command.arguments[6];
    _token = command.arguments[7];
    _productSecret = command.arguments[8];


    [[GizWifiSDK sharedInstance] setDeviceOnboarding:ssid
                                                 key:pwd
                                          configMode:[mode intValue]
                                    softAPSSIDPrefix:softAPSSIDPrefix
                                             timeout:[timeout intValue]
                                      wifiGAgentType:wifiAgentTypeArr];
}


/**
 *  cordova 获取设备列表
 *
 *  @param command [appid,[productkey],uid,token]
 */
- (void)getBoundDevices:(CDVInvokedUrlCommand *)command {
    [self init:command];
    currentState = getBoundDevicesCode;
    NSString *uid = command.arguments[0];
    NSString *token = command.arguments[1];
    NSArray *productkeys = [command.arguments objectAtIndex:2];
    _uid = uid;
    _token = token;
    [[GizWifiSDK sharedInstance] getBoundDevices:uid token:token
                              specialProductKeys:productkeys];
}

/**
 * cordova 非局域网绑定
 */
- (void)bindRemoteDevice:(CDVInvokedUrlCommand *)command {
    [self init:command];
    _uid = command.arguments[0];
    _token = command.arguments[1];
    NSString *mac = command.arguments[2];
    NSString *productKey = command.arguments[3];
    NSString *productSecret = command.arguments[4];
    _currentbindDeviceMac = mac;
    _currentBindDeviceProductKey = productKey;
    [[GizWifiSDK sharedInstance] bindRemoteDevice:_uid token:_token mac:mac productKey:productKey productSecret:productSecret];
}

/**
 *  cordova 设备remark,alias修改
 *
 *  @param command ["did","remark","alias"]
 */
- (void)setCustomInfo:(CDVInvokedUrlCommand *)command {
    [self init:command];
    NSString *did = command.arguments[0];
    NSString *remark = command.arguments[1];
    NSString *alias = command.arguments[2];
    BOOL isExist = false;
    for (GizWifiDevice *device in devices) {
        if (device.did == did) {
            device.delegate = self;
             isExist = true;
            [device setCustomInfo:remark alias:alias];
        }
    }
    if (isExist == false) {
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"This device does not exist!"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}


/**
 * cordova 设备解绑
 */
- (void)unbindDevice:(CDVInvokedUrlCommand *)command {
    [self init:command];
    _uid = command.arguments[0];
    _token = command.arguments[1];
    NSString *did = command.arguments[2];
    [[GizWifiSDK sharedInstance] unbindDevice:_uid token:_token did:did];
}

/**
 * cordova 订阅设备
 *
 *  @param command ["uid","token","did"]
 */
- (void)setSubscribe:(CDVInvokedUrlCommand *)command {
    [self init:command];
    NSString *did = command.arguments[0];
    BOOL subState = [command.arguments[1] boolValue];
    BOOL isExist = false;
    for (GizWifiDevice *device in devices) {
        if ([did isEqualToString:device.did]) {
            device.delegate = self;
            isExist = true;
            [device setSubscribe:subState];
        }
    }
    if (isExist == false) {
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"This device does not exist!"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }

}
/**
 * cordova 获取ssid列表
 *
 *  @param command []
 */
- (void)getWifiSSIDList:(CDVInvokedUrlCommand *)command {
    self.commandHolder = command;
    [[GizWifiSDK sharedInstance] getSSIDList];
}

/**
 *  cordova 开始device的监听
 *
 *  @param command []
 */
- (void)startDeviceListener:(CDVInvokedUrlCommand *)command {
    listenerCommandHolder = nil;
    listenerCommandHolder = command;
}

/**
 *  cordova 停止device的监听
 *
 *  @param command []
 */
- (void)stopDeviceListener:(CDVInvokedUrlCommand *)command {
    listenerCommandHolder = nil;
}

/**
 * cordova 发送控制指令
 * 设备订阅变成可控状态后，APP可以发送控制指令。控制指令是字典格式，键值对为数据点名称和值。操作指令的确认回复，通过didReceiveData回调返回。
   APP下发操作指令时可以指定sn，通过回调参数中的sn能够对应到下发指令是否发送成功了。但回调参数dataMap有可能是空字典，
   这取决于设备回复时是否携带当前数据点的状态。
   如果APP下发指令后只关心是否有设备状态上报，那么下发指令的sn可填0，这时回调参数sn也为0。
 *  @param command ["did","value"]
 */
- (void)write:(CDVInvokedUrlCommand *)command {
    NSString *did = command.arguments[0];
    NSMutableDictionary *value = command.arguments[1];
    BOOL isExist = false;
    writeCommandHolder = command;
    for (GizWifiDevice *device in devices) {
        if ([did isEqualToString:device.did]) {
            isExist = true;
            device.delegate = self;
            NSLog(@"Write data: %@", value);
            [device write:value withSN:1];
        } else {
            /**
             *  设备没有连接
             */
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"The device is not connected!"];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:writeCommandHolder.callbackId];
        }
    }
    if (isExist == false) {
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"This device does not exist!"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:writeCommandHolder.callbackId];
    }
}
/**
 *  cordova 获取硬件信息
 *
 *  不订阅设备也可以获取硬件信息。APP可以获取模块协议版本号，mcu固件版本号等硬件信息，但只有局域网设备才支持该功能。
 */
- (void)getHardwareInfo:(CDVInvokedUrlCommand *)command {
    getHardwareInfoCommandHolder = command;
    NSString *did = command.arguments[0];
    BOOL isExist = NO;//判断是否存在相同did的设备
    for (GizWifiDevice *device in devices) {
        if ([did isEqualToString:device.did]) {
            isExist = YES;
            device.delegate = self;
            [device getHardwareInfo];
        }
    }
    if (isExist == NO) {
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"This device does not exist!"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}


- (void)getDeviceStatus:(CDVInvokedUrlCommand *)command {
    NSString *did = command.arguments[0];
    BOOL isExist = false;
    for (GizWifiDevice *device in devices) {
        if ([did isEqualToString:device.did]) {
            device.delegate = self;
            isExist = true;
            [device getDeviceStatus];
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:[GwsdkUtils gizDeviceToDictionary:device]];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        }
    }
    if (isExist == false) {
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"This device does not exist!"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }

}



/**
 * 回调  新版本回调接口 16,08,30
 */
- (void)wifiSDK:(GizWifiSDK *)wifiSDK didSetDeviceOnboarding:(NSError *)result mac:(NSString *)mac
            did:(NSString *)did productKey:(NSString *)productKey {
    NSLog(@"code:%ld mac:%@ did:%@, productkey:%@", (long) result.code, mac, did, productKey);
    if (result.code == GIZ_SDK_SUCCESS) {
        // 配置成功
        switch (currentState) {
            case setDeviceOnboardingAndBindDeviceCode:
                _currentbindDeviceMac = mac;
                _currentBindDeviceProductKey = productKey;
                //执行非局域网设备绑定
                [[GizWifiSDK sharedInstance] bindRemoteDevice:_uid token:_token mac:mac productKey:productKey productSecret:_productSecret];
                break;
            case setDeviceOnboardingCode:
                //判断did是否存在
                if (mac.length > 0 && did.length > 0) {
                    NSMutableDictionary *d = [@{@"macAddress" : mac,
                            @"did" : did,
                            @"productKey" : productKey} mutableCopy];
                    CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:d];
                    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.commandHolder.callbackId];
                }
                break;
            default:
                break;
        }
    } else {
        // 配置失败
        if (_debug) {
            NSLog(@"======配置失败 \n error code:===%d", result);
        }
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsInt:result];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.commandHolder.callbackId];
    }
}
/**
 * 回调 设置设备绑定信息
 *
 * 不订阅设备也可以设置设备的绑定信息。在设备列表中找到要修改的设备，如果是已绑定的，就可以修改remark和alias信息。
 */
- (void)device:(GizWifiDevice *)device didSetCustomInfo:(NSError *)result {
    CDVPluginResult *pluginResult;
    if (result.code == GIZ_SDK_SUCCESS) {
        // 修改成功
        NSLog(@"\n =========didSetCustomInfo success========\n");
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:[GwsdkUtils gizDeviceToDictionary:device]];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.commandHolder.callbackId];
    } else {
        // 修改失败
        NSLog(@"\n =========didSetCustomInfo error========\n code:%ld", result.code);
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDouble:result.code];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.commandHolder.callbackId];
    }
}

/**
 * 回调  设备属性修改
 *
 * APP可以通过设备的mac、productKey、productSecret完成非局域网设备的绑定,可以用上述信息生成二维码，APP通过扫码方式绑定。GPRS设备、蓝牙设备等都是无法通过Wifi局域网发现的设备，都属于非局域网设备。
 */
- (void)wifiSDK:(GizWifiSDK *)wifiSDK didBindDevice:(NSError *)result did:(NSString *)did {
    if (result.code == GIZ_SDK_SUCCESS) {
        // 绑定成功
        NSLog(@"\n =========didBindDevice success========\n did:%@", did);
        NSMutableDictionary *d = [@{@"macAddress" : _currentbindDeviceMac,
                @"did" : did,
                @"productKey" : _currentBindDeviceProductKey} mutableCopy];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:d];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.commandHolder.callbackId];
    } else {
        // 绑定失败
        NSLog(@"\n =========didBindDevice error========\n code:@ld",result.code);
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDouble:(long) result.code];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.commandHolder.callbackId];
    }
}


/**
 * 回调 设备解绑
 *
 * 已绑定的设备可以解绑，解绑需要APP调用接口完成操作，SDK不支持自动解绑。对于已订阅的设备，解绑成功时会被解除订阅，同时断开设备连接，设备状态也不会再主动上报了。设备解绑后，APP刷新绑定设备列表时就得不到该设备了。
 */
- (void)wifiSDK:(GizWifiSDK *)wifiSDK didUnbindDevice:(NSError *)result did:(NSString *)did {
    if (result.code == GIZ_SDK_SUCCESS) {
        // 解绑成功
        NSLog(@"\n =========didUnbindDevice success========\n %@", did);
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:did];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.commandHolder.callbackId];
    } else {
        // 解绑失败
        NSLog(@"\n =========didUnbindDevice error========\n errorCode:%ld ", result.code);
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDouble:result.code];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.commandHolder.callbackId];
    }
}

/**
 * 回调 设备订阅回调
 */
- (void)device:(GizWifiDevice *)device didSetSubscribe:(NSError *)result isSubscribed:(BOOL)isSubscribed {
    CDVPluginResult *pluginResult;
    if (result.code == GIZ_SDK_SUCCESS) {
        //订阅或解绑订阅成功
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:[GwsdkUtils gizDeviceToDictionary:device]];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.commandHolder.callbackId];
    } else {
        //操作失败
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDictionary:[GwsdkUtils gizDeviceToDictionary:device]];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.commandHolder.callbackId];
    }
}

/**
 * 回调 获取硬件信息
 * 不订阅设备也可以获取硬件信息。APP可以获取模块协议版本号，mcu固件版本号等硬件信息，但只有局域网设备才支持该功能。
 */
- (void)device:(GizWifiDevice *)device didGetHardwareInfo:(NSError *)result hardwareInfo:(NSDictionary *)hardwareInfo {
    if (result.code == GIZ_SDK_SUCCESS) {
        // 获取成功
        NSString *hardWareInfo = [NSString stringWithFormat:@"WiFi Hardware Version: %@,"
                                                                    "\nWiFi Software Version: %@,"
                                                                    "\n MCU Hardware Version: %@,"
                                                                    "\n MCU Software Version: %@, "
                                                                    "\nFirmware Id: %@,"
                                                                    "\nFirmware Version: %@,"
                                                                    " \nProduct Key: %@"
                , [hardwareInfo valueForKey:@"wifiHardVersion"]
                , [hardwareInfo valueForKey:@"wifiSoftVersion"]
                , [hardwareInfo valueForKey:@"mcuHardVersion"]
                , [hardwareInfo valueForKey:@"mcuSoftVersion"]
                , [hardwareInfo valueForKey:@"wifiFirmwareId"]
                , [hardwareInfo valueForKey:@"wifiFirmwareVer"]
                , [hardwareInfo valueForKey:@"productKey"]];
        NSLog(@"=========didQueryHardwareInfo=========\n %@", hardWareInfo);

        NSMutableDictionary *dInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                [hardwareInfo valueForKey:@"wifiHardVersion"], @"XPGWifiDeviceHardwareWifiHardVer",
                [hardwareInfo valueForKey:@"wifiSoftVersion"], @"XPGWifiDeviceHardwareWifiSoftVer",
                [hardwareInfo valueForKey:@"mcuHardVersion"], @"XPGWifiDeviceHardwareMCUHardVer",
                [hardwareInfo valueForKey:@"mcuSoftVersion"], @"XPGWifiDeviceHardwareMCUSoftVer",
                [hardwareInfo valueForKey:@"wifiFirmwareId"], @"XPGWifiDeviceHardwareFirmwareId",
                [hardwareInfo valueForKey:@"wifiFirmwareVer"], @"XPGWifiDeviceHardwareFirmwareVer",
                [hardwareInfo valueForKey:@"productKey"], @"XPGWifiDeviceHardwareProductKey",
                device.did, @"did",
                device.macAddress, @"macAddress",
                        nil];
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dInfo];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:getHardwareInfoCommandHolder.callbackId];
    } else {
        // 获取失败
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDouble:result.code];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:getHardwareInfoCommandHolder.callbackId];
    }
}

/**
 * 回调  接收设备列表变化上报
 *
 * APP设置好委托，启动SDK后，就可以收到SDK的设备列表推送。每次局域网设备或者用户绑定设备发生变化时，SDK都会主动上报最新的设备列表。设备断电再上电、有新设备上线等都会触发设备列表发生变化。用户登录后，SDK会主动把用户已绑定的设备列表上报给APP，绑定设备在不同的手机上登录帐号都可获取到。
   如果APP想要刷新绑定设备列表，可以调用绑定设备列表接口，同时可以指定自己关心的产品类型标识，SDK会把筛选后的设备列表返回给APP。
   SDK提供设备列表缓存，设备列表中的设备对象在整个APP生命周期中一直有效。缓存的设备列表会与当前最新的已发现设备同步更新。
 */
- (void)wifiSDK:(GizWifiSDK *)wifiSDK didDiscovered:(NSError *)result deviceList:(NSArray *)deviceList {
    // 提示错误原因
    if (result.code == GIZ_SDK_SUCCESS) {
        NSLog(@"didDiscovered result: %@", result.localizedDescription);
        //每timer秒获取一次设备列表。
        if (startDeviceListCommandHolder != nil) {
            NSMutableArray *jsonArray = [[NSMutableArray alloc] init];
            for (GizWifiDevice *device in deviceList) {
                [jsonArray addObject:[GwsdkUtils gizDeviceToDictionary:device]];
            }
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:jsonArray];
            [pluginResult setKeepCallbackAsBool:true];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:startDeviceListCommandHolder.callbackId];
        }
        switch (currentState) {
            case getBoundDevicesCode: {
                NSMutableArray *jsonArray = [[NSMutableArray alloc] init];
                for (GizWifiDevice *device in deviceList) {
                    [jsonArray addObject:[GwsdkUtils gizDeviceToDictionary:device]];
                }
                CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:jsonArray];
                [pluginResult setKeepCallbackAsBool:true];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:self.commandHolder.callbackId];
                break;
            }
            default:
                break;
        }
    }
    // 显示变化后的设备列表
    NSLog(@"discovered deviceList: %@", deviceList);
    devices = deviceList;
}

/**
 * 回调 接收设备状态
 *
 * 设备订阅变成可控状态后，APP可以随时收到设备状态的主动上报，仍然通过didReceiveData回调返回。设备上报状态时，回调参数sn为0，回调参数dataMap为设备上报的状态。
 */
- (void)device:(GizWifiDevice *)device didReceiveData:(NSError *)result data:(NSDictionary *)dataMap withSN:(NSNumber *)sn {
    if (result.code == GIZ_SDK_SUCCESS) {
        NSLog(@"sn:%@", sn);
        //如果sn 为1 代表是控制命令
        if ([sn isEqualToNumber:@1]) {
            if (writeCommandHolder != nil) {
                CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:writeCommandHolder.callbackId];
            }
        }else{
        // 已定义的设备数据点，有布尔、数值、枚举、扩展类型
        NSDictionary *dataDict = dataMap[@"data"];
        NSLog(@"已定义的设备数据点%@", dataDict);
        // 扩展类型数据点，key如果是“extData”
        NSData *extData = dataMap[@"extdata"];
        NSLog(@"扩展数据extData：%@", extData);
        // 已定义的设备故障或报警数据点，设备发生故障或报警后该字段有内容，没有发生故障或报警则没内容
        NSDictionary *alertsDict = dataMap[@"alerts"];
        NSDictionary *faultsDict = dataMap[@"faults"];
        NSLog(@"报警：%@, 故障：%@", alertsDict, faultsDict);
        // 透传数据，无数据点定义，适合开发者自行定义协议做数据解析
        NSData *binary = dataMap[@"binary"];
        NSLog(@"透传数据：%@", binary);
        NSString *did = device.did;
        NSMutableDictionary *d;
        d = [dataMap mutableCopy];
        d[@"did"] = did;
        d[@"device"] = [GwsdkUtils gizDeviceToDictionary:device];
        if (listenerCommandHolder != nil) {
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:d];
            [pluginResult setKeepCallbackAsBool:true];
            [self.commandDelegate sendPluginResult:pluginResult callbackId:listenerCommandHolder.callbackId];
        }
        }
    } else {
        //出错，处理 result 信息
        NSLog(@"\n================didReceiveData error====\ndid:%ld", (long) result.code);
        if (sn == [NSNumber numberWithInt:1]) {
            if (writeCommandHolder != nil) {
                CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsDouble:result.code];
                [self.commandDelegate sendPluginResult:pluginResult callbackId:writeCommandHolder.callbackId];
            }
        }
    }
}

// 实现系统事件通知回调
- (void)wifiSDK:(GizWifiSDK *)wifiSDK didNotifyEvent:(GizEventType)eventType eventSource:(id)eventSource eventID:(GizWifiErrorCode)eventID eventMessage:(NSString *)eventMessage {
    if (eventType == GizEventSDK) {
        // SDK发生异常的通知
        NSLog(@"SDK event happened: [%@] = %@", @(eventID), eventMessage);
    }
    else if (eventType == GizEventDevice) {
        // 设备连接断开时可能产生的通知
        GizWifiDevice *mDevice = (GizWifiDevice *) eventSource;
        NSLog(@"device mac %@ disconnect caused by %@", mDevice.macAddress, eventMessage);
    }
    else if (eventType == GizEventM2MService) {
        // M2M服务返回的异常通知
        NSLog(@"M2M domain %@ exception happened: [%@] = %@", (NSString *) eventSource, @(eventID), eventMessage);
    }
    else if (eventType == GizEventToken) {
        // token失效通知
        NSLog(@"token %@ expired: %@", (NSString *) eventSource, eventMessage);
    }
}

/**
 * 回调 2.0 SDK会自动探测配置文件是否有更新，有更新时会主动推送给APP。
 * APP只保留didUpdateProduct回调即可，不需要再使用updateDeviceFromServer这个兼容接口做强制更新了。
 */
- (void)wifiSDK:(GizWifiSDK *)wifiSDK didUpdateProduct:(NSError *)result producKey:(NSString *)productKey productUI:(NSString *)productUI {
    if (result.code == GIZ_SDK_SUCCESS) {
        NSLog(@"======didUpdateProduct==Success===\nproduct:%@\nresult:%d \nproductUI:%@", productKey, result, productUI);
    } else {
        NSLog(@"======didUpdateProduct==Error===\nproduct:%@\nresult:%d \nproductUI:%@", productKey, result, productUI);
    }
}

/**
 *  cordova 释放内存
 *
 *  @param command []
 */
- (void)dealloc:(CDVInvokedUrlCommand *)command {
    NSLog(@"//====dealloc...====");
    _currentPairDeviceMacAddress = nil;

     [GizWifiSDK sharedInstance].delegate = nil;
    [GizWifiSDK sharedInstance].delegate = self;
}


- (void)dispose {
    NSLog(@"//====disposed...====");
    _currentPairDeviceMacAddress = nil;
    [GizWifiSDK sharedInstance].delegate = nil;
    [GizWifiSDK sharedInstance].delegate = self;
}

@end
