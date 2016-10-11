这是机智云SDK接口文档



接口列表:
- [cordova.plugins.gwsdk.getHardwareInfo](#getHardwareInfo)
- [更新日志](#更新日志)

###getHardwareInfo
获取设备硬件信息

    cordova.plugins.gwsdk.getHardwareInfo(did,success,error)

###Parameters

    did:设备的did
    success:成功的回调
    error:失败的回调

### Description

    success {
        // 字符串类型，GAgent模组硬件版本号
        XPGWifiDeviceHardwareWifiHardVer:"",
        // 字符串类型，GAgent模组软件版本号
        XPGWifiDeviceHardwareWifiSoftVer:"",
        // 字符串类型，设备硬件版本号
        XPGWifiDeviceHardwareMCUHardVer:"",
        //MCU软件版本
        XPGWifiDeviceHardwareMCUSoftVer:"",
        // 字符串类型，固件Id
        XPGWifiDeviceHardwareFirmwareId:"",
        // 字符串类型，固件版本号
        XPGWifiDeviceHardwareFirmwareVer:"",
        // 字符串类型，设备的Productkey
        XPGWifiDeviceHardwareProductKey:"",
        //字符串类型,设备的did
        did:"",
        //字符串类型,设备的macAddress
        macAdress:""
    }
    error:
      //错误码,错误码对比参见机智云.
      
#更新日志
  
####Wi-Fi设备接入SDK for iOS & android
    更新时间: 2016.2.15
    发布时间：2016.2.06 17:45
    版本号：1.6.2.16020616
      1、解决SDK的cpu占用率过高问题
      2、解决设备重置配置上线后，概率性出现绑定失败和登录失败问题
      3、修复设备remark被小循环覆盖为空的问题
      4、修复SDK上报到云端的模组日志，云端无法解析问题
      5、改善设备登录后连接稳定性问题
      6、解决iOS同时连接两个设备，退到后台时，只回调了一个设备的连接断开问题
      7、解决iOS从后台回到前台时，已断开的大循环设备第一次重连时登录失败问题
      8、修复设备登录时小概率崩溃
####version 0.4.2
        更新时间: 2016.2.19 14:37
        sha-1:  bf8b7be6762a149a46a52e7759643f39a5855c8e
      1.添加配网绑定方法.
      2.解决appid的切换问题
    
####version 0.4.3
        更新时间: 2016.2.19 15:50
        sha-1:  9c203b11bb2c6a9d9a1408a05b02235dc0408c42
      1.setDevicewifi添加timeout字段.
####version 0.5.1
        更新时间: 2016.3.9 12:42
    
       1.添加android 和ios 小循环接口
       2.优化android 代码
####version 0.5.2
        更新时间: 2016.4.14 18:25
    
       1.添加getHardwareInfo 接口
####version 0.6.0
        更新时间 2016.08.30
        1.更新 sdk 版本。
         发布时间:2016.8.03 22:55
         版本号：2.02.02
        更新日志:
            ios:
                 1、调整设备指令超时时间
                 2、修复枚举数据点解析bug
                 3、调整日志上传策略
                 4、去除状态查询空状态回复
                 5、调整配置文件更新策略
                 6、提高域名切换时设备列表获取的准确性
                 7、优化TCP传输效率
                 8、枚举数据点上报内容变更，由字符串变更为枚举序号（App需重点关注）
                 9、增加对旧版本数据点下发的兼容
                 10、增加对旧版本故障报警上报类型兼容
            android:
                1、调整设备指令超时时间
                2、修复枚举数据点解析bug
                3、调整日志上传策略
                4、去除状态查询空状态回复
                5、调整配置文件更新策略
                6、提高域名切换时设备列表获取的准确性
                7、优化TCP传输效率
                8、修改外网检测方式
                9、增加对旧版本数据点下发的兼容
                10、增加对旧版本故障报警上报类型兼容
                11、更新汉枫V7配置库  
####version 0.6.1
        更新时间 2016.09.21
        发布时间：2016.9.07 23:2
        版本号：2.03.03
        更新日志：
            ios:
                 1、新增以下定时任务功能接口：
                 （1）创建定时任务：createScheduler
                 （2）获取定时任务列表：getSchedulers
                 （3）删除定时任务：deleteScheduler
                 （4）查询定时任务执行状态：getSchedulerStatus
                2、用户有已绑定设备时，支持设备绑定解绑推送
                3、支持中控子设备在线状态变化通知
                4、更换最新版本庆科配置库
                5、修复域名切换后配置文件更新不及时的bug
                6、修复无外网小循环设备发现的bug
                7、更及时的更新设备列表
            android:
                 1、新增以下定时任务功能接口：
                  （1）创建定时任务：createScheduler
                  （2）获取定时任务列表：getSchedulers
                  （3）删除定时任务：deleteScheduler
                  （4）查询定时任务执行状态：getSchedulerStatus
                 2、用户有已绑定设备时，支持设备绑定解绑推送
                 3、支持中控子设备在线状态变化通知
                 4、更换最新版本庆科配置库
                 5、修复域名切换后配置文件更新不及时的bug
                 6、修复无外网小循环设备发现的bug
                 7、更及时的更新设备列表
                 8、修复在特定Android手机型号上偶尔出现的崩溃
                 9、增加对x86架构Android平台的支持