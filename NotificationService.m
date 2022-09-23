//
//  NotificationService.m
//  NotificationService
//
//  Created by zoujing on 2020/4/21.
//  Copyright © 2020 gleen. All rights reserved.
//
#import <UIKit/UIKit.h>
#import "NotificationService.h"
#import <AVFoundation/AVFoundation.h>

@interface NotificationService ()<AVSpeechSynthesizerDelegate>
@property (nonatomic, strong) void (^contentHandler)(UNNotificationContent *contentToDeliver);
@property (nonatomic, strong) UNMutableNotificationContent *bestAttemptContent;
@property (nonatomic) AVSpeechSynthesizer *av;

@end

@implementation NotificationService


- (void)didReceiveNotificationRequest:(UNNotificationRequest *)request withContentHandler:(void (^)(UNNotificationContent * _Nonnull))contentHandler {
    self.contentHandler = contentHandler;
    self.bestAttemptContent = [request.content mutableCopy];
    
    // Modify the notification content here...
//    self.bestAttemptContent.title = [NSString stringWithFormat:@"%@ [modified]", self.bestAttemptContent.title];
    
    //是否音频推送类型
    NSString *notificationType = self.bestAttemptContent.userInfo[@"notificationType"];
    if ([notificationType isEqualToString:@"10"]) {
        //播放收款音频
        self.bestAttemptContent.title = @"";
        
        self.bestAttemptContent.subtitle = @"";
        
        NSDictionary *alertData = self.bestAttemptContent.userInfo[@"alert"];

        NSString *alertBody = alertData[@"body"];

        self.bestAttemptContent.body = alertBody;
        
        self.bestAttemptContent.sound = nil;
        
        NSString *version = [UIDevice currentDevice].systemVersion;
        
        if (version.doubleValue >= 12.1){
            VoiceBoradcastModel *vbModel = [self dealWithApnsInfo:self.bestAttemptContent.userInfo];
            NSMutableArray *voiceArr = [self voiceSourceArray:vbModel];
            
            for (NSDictionary *dic in voiceArr) {
                float timeWait = [dic[@"time"] floatValue];
                dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
                [self registerNotificationWithString:dic[@"voice"] completeHandler:^{
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeWait * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        
                        dispatch_semaphore_signal(semaphore);
                        
                    });
                }];
                dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            }
            self.contentHandler(self.bestAttemptContent);
        } else {
            [self starSpeak:self.bestAttemptContent.userInfo[@"aps"][@"alert"]];
        }
    } else {
        self.contentHandler(self.bestAttemptContent);
    }
}

- (void)starSpeak:(NSString *) str {
    //初始化对象
    self.av = [[AVSpeechSynthesizer alloc] init];
    self.av.delegate = self;
    AVSpeechUtterance*utterance = [[AVSpeechUtterance alloc]initWithString:str];//需要转换的文字
    //你有一笔新订单  0.55
    if ([str hasSuffix:@"新订单"]) {
        utterance.rate = 0.54;
    }else{
        utterance.rate = 0.5;
    }
    // 设置语速，范围0-1，注意0最慢，1最快；AVSpeechUtteranceMinimumSpeechRate最慢，AVSpeechUtteranceMaximumSpeechRate最快
    AVSpeechSynthesisVoice *voice = [AVSpeechSynthesisVoice voiceWithLanguage:@"zh-CN"];//设置发音，这是中文普通话
    utterance.voice = voice;
    [self.av speakUtterance:utterance];//开始
    
    self.contentHandler(self.bestAttemptContent);
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didStartSpeechUtterance:(AVSpeechUtterance *)utterance {
    
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)utterance {
    self.contentHandler(self.bestAttemptContent);
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didCancelSpeechUtterance:(AVSpeechUtterance *)utterance {
    self.contentHandler(self.bestAttemptContent);
}


- (void)serviceExtensionTimeWillExpire {
    self.contentHandler(self.bestAttemptContent);
}

- (VoiceBoradcastModel *)dealWithApnsInfo:(NSDictionary *)apns {
    VoiceBoradcastModel *vbModel = [[VoiceBoradcastModel alloc] init];
    //    收款提醒：您成功收款一笔：99.45元！
    //    收款554元
    //    优惠收款314元
    //    你有一笔新订单
    NSDictionary *alertData = apns[@"aps"][@"alert"];
    NSString *alertBody = alertData[@"body"];
    NSString *voiceText = alertBody;
    
    if ([voiceText hasPrefix:@"你有一笔新订单"]) {
        vbModel.haveNumber = NO;
        vbModel.wholeText = voiceText;
    }else{
        vbModel.haveNumber = YES;
        if ([voiceText hasPrefix:@"收款提醒"]) {
            NSRange frontRange = NSMakeRange(0, 13);
            NSString *frontStr = [voiceText substringWithRange:frontRange];
            NSRange behindRange = NSMakeRange(voiceText.length - 2, 2);
            NSString *behindStr = [voiceText substringWithRange:behindRange];
            NSRange middleRange = NSMakeRange(13, voiceText.length - 15);
            NSString *middleStr = [voiceText substringWithRange:middleRange];
            
            vbModel.frontText = frontStr;
            vbModel.middleNumberText = middleStr;
            vbModel.behindText = behindStr;
            
        }else if([voiceText hasPrefix:@"收款"]){
            NSRange frontRange = NSMakeRange(0, 2);
            NSString *frontStr = [voiceText substringWithRange:frontRange];
            NSRange behindRange = NSMakeRange(voiceText.length - 1, 1);
            NSString *behindStr = [voiceText substringWithRange:behindRange];
            NSRange middleRange = NSMakeRange(2, voiceText.length - 3);
            NSString *middleStr = [voiceText substringWithRange:middleRange];
            
            vbModel.frontText = frontStr;
            vbModel.middleNumberText = middleStr;
            vbModel.behindText = behindStr;
        }else if([voiceText hasPrefix:@"优惠收款"]){
            NSRange frontRange = NSMakeRange(0, 4);
            NSString *frontStr = [voiceText substringWithRange:frontRange];
            NSRange behindRange = NSMakeRange(voiceText.length - 1, 1);
            NSString *behindStr = [voiceText substringWithRange:behindRange];
            NSRange middleRange = NSMakeRange(4, voiceText.length - 5);
            NSString *middleStr = [voiceText substringWithRange:middleRange];
            
            vbModel.frontText = frontStr;
            vbModel.middleNumberText = middleStr;
            vbModel.behindText = behindStr;
            
        }
    }
    
    return vbModel;
}

- (NSMutableArray *)voiceSourceArray:(VoiceBoradcastModel *)model {
    NSMutableArray *voiceArray = [[NSMutableArray alloc] init];
    
    if (model.haveNumber) {
        //前边文字
        if ([model.frontText hasPrefix:@"收款提醒"]) {//收款提醒：你成功收款一笔
            [voiceArray addObject:@{@"voice":@"t1.mp3",@"time":@"3.8"}];
        }else if([model.frontText hasPrefix:@"收款"]){
            [voiceArray addObject:@{@"voice":@"t2.mp3",@"time":@"1"}];
        }else if([model.frontText hasPrefix:@"优惠收款"]){
            [voiceArray addObject:@{@"voice":@"t3.mp3",@"time":@"2"}];
        }
        
        //中间数字
        NSDecimalNumber *number = [[NSDecimalNumber alloc] initWithString:model.middleNumberText];
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
        formatter.numberStyle = kCFNumberFormatterRoundHalfDown;
        NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:@"zh_Hans"];
        formatter.locale = locale;
        NSString *numberStr = [formatter stringFromNumber:number];
        //123456789.01         一亿二千三百四十五万六千七百八十九点〇一
        NSArray *numberArr = [numberStr componentsSeparatedByString:@"点"];
        
        //前边一部分
        NSString *firstNumberStr = numberArr[0];
        for (int i = 0; i < firstNumberStr.length; i ++) {
            NSRange range = NSMakeRange(i, 1);
            NSString *subStr = [firstNumberStr substringWithRange:range];
            [voiceArray addObject:[self numberVoiceWith:subStr]];
        }
        //没有小数点
        if ([numberArr count] == 1) {
            
        }else{
            //后边一部分
            NSString *lastNumberStr = numberArr[1];
            if ([lastNumberStr isEqualToString:@"〇〇"]) {
                
            }else{
                //点
                [voiceArray addObject:@{@"voice":@"dot.mp3",@"time":@"0.5"}];
                NSString *firstSubStr = @"";
                NSString *secondSubStr = @"";
                //最多循环两次
                int count = 2;
                if (lastNumberStr.length < 2) {
                    count = (int)lastNumberStr.length;
                }
                //判断最后两位是否相等 如果相等 则两个数字取得音频文件不能一样 否则第二个数字读不出来
                for (int i = 0; i < count; i ++) {
                    NSRange range = NSMakeRange(i, 1);
                    NSString *subStr = [lastNumberStr substringWithRange:range];
                    
                    if (i == 0) {
                        firstSubStr = subStr;
                    }else{
                        secondSubStr = subStr;
                    }
                }
                if ([firstSubStr isEqualToString:secondSubStr]) {
                    NSDictionary *firstVoiceDic = [self numberVoiceWith:firstSubStr];
                    NSMutableDictionary *secondVoiceDic = [[NSMutableDictionary alloc] initWithDictionary:firstVoiceDic];
                    [secondVoiceDic setObject:[NSString stringWithFormat:@"copy_%@",firstVoiceDic[@"voice"]] forKey:@"voice"];
                    [voiceArray addObject:firstVoiceDic];
                    [voiceArray addObject:secondVoiceDic];
                }else{
                    if (firstSubStr.length > 0) {
                        [voiceArray addObject:[self numberVoiceWith:firstSubStr]];
                    }
                    if (secondSubStr.length > 0) {
                        [voiceArray addObject:[self numberVoiceWith:secondSubStr]];
                    }
                }
            }
        }
        //最后一个元
        [voiceArray addObject:@{@"voice":@"yuan.mp3",@"time":@"0.5"}];
    }else{
        [voiceArray addObject:@{@"voice":@"t4.mp3",@"time":@"2"}];
    }
    return voiceArray;
}

- (NSDictionary *)numberVoiceWith:(NSString *) text {
    NSDictionary *voice = @{};
    //    一亿二千三百四十五万六千七百八十九点〇一
    NSMutableDictionary *voiceDictionary = [[NSMutableDictionary alloc] init];
    [voiceDictionary setObject:@"1.mp3" forKey:@"一"];
    [voiceDictionary setObject:@"2.mp3" forKey:@"二"];
    [voiceDictionary setObject:@"3.mp3" forKey:@"三"];
    [voiceDictionary setObject:@"4.mp3" forKey:@"四"];
    [voiceDictionary setObject:@"5.mp3" forKey:@"五"];
    [voiceDictionary setObject:@"6.mp3" forKey:@"六"];
    [voiceDictionary setObject:@"7.mp3" forKey:@"七"];
    [voiceDictionary setObject:@"8.mp3" forKey:@"八"];
    [voiceDictionary setObject:@"9.mp3" forKey:@"九"];
    [voiceDictionary setObject:@"0.mp3" forKey:@"〇"];
    [voiceDictionary setObject:@"shi.mp3" forKey:@"十"];
    [voiceDictionary setObject:@"bai.mp3" forKey:@"百"];
    [voiceDictionary setObject:@"qian.mp3" forKey:@"千"];
    [voiceDictionary setObject:@"wan.mp3" forKey:@"万"];
    [voiceDictionary setObject:@"yi.mp3" forKey:@"亿"];
    [voiceDictionary setObject:@"dot.mp3" forKey:@"点"];
    
    NSString *voiceStr = voiceDictionary[text];
    if (!voiceStr) {
        voiceStr = @"";
    }
    
    voice = @{@"voice":voiceStr,@"time":@"0.5"};
    
    return voice;
}

- (void)registerNotificationWithString:(NSString *)string completeHandler:(dispatch_block_t)complete {
    [[UNUserNotificationCenter currentNotificationCenter] requestAuthorizationWithOptions:(UNAuthorizationOptionAlert | UNAuthorizationOptionSound | UNAuthorizationOptionBadge) completionHandler:^(BOOL granted, NSError * _Nullable error) {
        
        if (granted) {
            UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc]init];
            content.title = @"";
            content.subtitle = @"";
            content.body = @"";
            content.sound = [UNNotificationSound soundNamed:string];
            content.categoryIdentifier = [NSString stringWithFormat:@"categoryIndentifier%@",string];
            
            UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:0.01 repeats:NO];
            UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:[NSString stringWithFormat:@"categoryIndentifier%@",string] content:content trigger:trigger];
            
            [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
                if (error == nil) {
                    if (complete) {
                        complete();
                    }
                }
            }];
        }
    }];
}

@end

@implementation VoiceBoradcastModel

@end
