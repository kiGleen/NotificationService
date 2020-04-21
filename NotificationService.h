//
//  NotificationService.h
//  NotificationService
//
//  Created by zoujing@gogpay.cn on 2020/4/21.
//  Copyright © 2020 cn.gogpay.dcb. All rights reserved.
//

#import <UserNotifications/UserNotifications.h>

@interface NotificationService : UNNotificationServiceExtension

@end

/**
 语音播报实体对象
 */
@interface VoiceBoradcastModel : NSObject

@property (nonatomic) BOOL haveNumber;//是否含有数字

/**
 前边文字
 */
@property (nonatomic) NSString *frontText;

/**
 中间数字
 */
@property (nonatomic) NSString *middleNumberText;

/**
 后边文字
 */
@property (nonatomic) NSString *behindText;


/**
 全是文字
 */
@property (nonatomic) NSString *wholeText;

@end
