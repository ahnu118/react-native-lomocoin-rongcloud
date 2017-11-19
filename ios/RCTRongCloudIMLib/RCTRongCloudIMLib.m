//
//  RCTRongCloudIMLib.m
//  RCTRongCloudIMLib
//
//  Created by lomocoin on 10/21/2017.
//  Copyright © 2017 lomocoin.com. All rights reserved.
//

#import "RCTRongCloudIMLib.h"

#import <AssetsLibrary/AssetsLibrary.h>
#import <AVFoundation/AVFoundation.h>

@interface RCTRongCloudIMLib ()

{
    BOOL       _isSend;    //是否已发送
    NSTimer *  _longTimer; //60s定时器
    NSInteger  _duration;  //语音时长
}

@property (nonatomic, strong) NSDate * startDate;
@property (nonatomic, strong) NSDate * endDate;
@property (nonatomic, strong) AVAudioSession *session;
@property (nonatomic, strong) AVAudioRecorder *recorder;//录音器
@property (nonatomic, strong) AVAudioPlayer *player; //播放器
@property (nonatomic, strong) NSURL *recordFileUrl; //语音路径

@end

@implementation RCTRongCloudIMLib

@synthesize bridge = _bridge;


RCT_EXPORT_MODULE(RongCloudIMLibModule)

- (NSArray<NSString *> *)supportedEvents
{
    return @[@"onRongMessageReceived", @"onRongConnectionStatus"];
}

#pragma mark RongCloud Init

RCT_EXPORT_METHOD(initWithAppKey:(NSString *)appkey) {
    NSLog(@"initWithAppKey %@", appkey);
    [[self getClient] initWithAppKey:appkey];
    
    [[self getClient] setReceiveMessageDelegate:self object:nil];
}

#pragma mark RongCloud Connect

RCT_EXPORT_METHOD(connectWithToken:(NSString *) token
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject) {
    NSLog(@"connectWithToken %@", token);
    
    [self setupPushNotificationsDeviceToken];
    
    void (^successBlock)(NSString *userId);
    successBlock = ^(NSString* userId) {
        NSArray *events = [[NSArray alloc] initWithObjects:userId,nil];
        resolve(events);
    };
    
    void (^errorBlock)(RCConnectErrorCode status);
    errorBlock = ^(RCConnectErrorCode status) {
        NSString *errcode;
        switch (status) {
            case RC_CONN_ID_REJECT:
                errcode = @"RC_CONN_ID_REJECT";
                break;
            case RC_CONN_TOKEN_INCORRECT:
                errcode = @"RC_CONN_TOKEN_INCORRECT";
                break;
            case RC_CONN_NOT_AUTHRORIZED:
                errcode = @"RC_CONN_NOT_AUTHRORIZED";
                break;
            case RC_CONN_PACKAGE_NAME_INVALID:
                errcode = @"RC_CONN_PACKAGE_NAME_INVALID";
                break;
            case RC_CONN_APP_BLOCKED_OR_DELETED:
                errcode = @"RC_CONN_APP_BLOCKED_OR_DELETED";
                break;
            case RC_DISCONN_KICK:
                errcode = @"RC_DISCONN_KICK";
                break;
            case RC_CLIENT_NOT_INIT:
                errcode = @"RC_CLIENT_NOT_INIT";
                break;
            case RC_INVALID_PARAMETER:
                errcode = @"RC_INVALID_PARAMETER";
                break;
            case RC_INVALID_ARGUMENT:
                errcode = @"RC_INVALID_ARGUMENT";
                break;
                
            default:
                errcode = @"OTHER";
                break;
        }
        reject(errcode, [NSString stringWithFormat:@"status :%ld  errcode: %@",(long)status,errcode], nil);
    };
    void (^tokenIncorrectBlock)();
    tokenIncorrectBlock = ^() {
        reject(@"TOKEN_INCORRECT", @"tokenIncorrect", nil);
    };
    
    [[self getClient] connectWithToken:token success:successBlock error:errorBlock tokenIncorrect:tokenIncorrectBlock];
    
}

#pragma mark  RongCloud  GetMessagesFromLocal

RCT_EXPORT_METHOD(clearUnreadMessage:(int)type
                  targetId:(NSString *)targetId) {
    
    RCConversationType conversationType;
    switch (type) {
        case 1:
            conversationType = ConversationType_PRIVATE;
            break;
        case 3:
            conversationType = ConversationType_GROUP;
            break;
            
        default:
            conversationType = ConversationType_PRIVATE;
            break;
    }
    
    [[self getClient] clearMessagesUnreadStatus:conversationType targetId:targetId];
}

/*!
 删除某个会话中的所有消息
 
 @param conversationType    会话类型，不支持聊天室
 @param targetId            目标会话ID
 @return                    是否删除成功
 */
RCT_EXPORT_METHOD(clearMessages:(int)type
                  targetId:(NSString *)targetId
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    BOOL flag =  [[self getClient] clearMessages:type targetId:targetId];
    if(flag){
        resolve(@"删除成功");
    }else{
        reject(@"删除失败", @"删除失败", nil);
    }
}

/*!
 从本地存储中删除会话
 
 @param conversationType    会话类型
 @param targetId            目标会话ID
 @return                    是否删除成功
 
 @discussion 此方法会从本地存储中删除该会话，但是不会删除会话中的消息。
 */
RCT_EXPORT_METHOD(removeConversation:(int)type
                  targetId:(NSString *)targetId
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    BOOL flag = [[self getClient] removeConversation:type targetId:targetId];
    if(flag){
        resolve(@"删除成功");
    }else{
        reject(@"删除失败", @"删除失败", nil);
    }
}

/*!
 发送某个会话中消息阅读的回执
 
 @param conversationType    会话类型
 @param targetId            目标会话ID
 @param timestamp           该会话中已阅读的最后一条消息的发送时间戳
 
 @discussion 此接口目前只支持单聊, 如果使用Lib 可以注册监听 RCLibDispatchReadReceiptNotification 通知,使用kit 直接开启RCIM.h 中enableReadReceipt。
 
 @warning 此接口目前仅支持单聊。
 */
RCT_EXPORT_METHOD(sendReadReceiptMessage:(int)type
                  targetId:(NSString *)targetId
                  time:(long long)timestamp
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    void (^successBlock)();
    successBlock = ^() {
        resolve(@"成功");
    };
    
    void (^errorBlock)(RCErrorCode status);
    errorBlock = ^(RCErrorCode status) {
        reject(@"发送失败", @"发送失败", nil);
    };
    [[self getClient] sendReadReceiptMessage:type targetId:(NSString *)targetId time:timestamp success:successBlock error:errorBlock];
}

/*!
 设置会话的置顶状态
 
 @param conversationType    会话类型
 @param targetId            目标会话ID
 @param isTop               是否置顶
 @return                    设置是否成功
 */
RCT_EXPORT_METHOD(setConversationToTop:(int)type
                  targetId:(NSString *)targetId
                  isTop:(BOOL)isTop
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    BOOL flag = [[self getClient] setConversationToTop:type targetId:targetId isTop:isTop];
    if(flag){
        resolve(@"置顶成功");
    }else{
        reject(@"置顶失败", @"置顶失败", nil);
    }
}


/*!
 获取单个会话数据
 
 @param conversationType    会话类型
 @param targetId            目标会话ID
 @return                    会话的对象
 */
RCT_EXPORT_METHOD(getConversation:(int)conversationType
                  targetId:(NSString *)targetId
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    RCConversation *conversation = [[self getClient] getConversation:conversationType targetId:targetId];
    NSMutableDictionary * dict = [NSMutableDictionary new];
    dict[@"conversationType"] = @((unsigned long)conversation.conversationType);
    dict[@"targetId"] = conversation.targetId;
    dict[@"conversationTitle"] = conversation.conversationTitle;
    dict[@"unreadMessageCount"] = @(conversation.unreadMessageCount);
    dict[@"receivedTime"] = @((long long)conversation.receivedTime);
    dict[@"sentTime"] = @((long long)conversation.sentTime);
    dict[@"senderUserId"] = conversation.senderUserId;
    dict[@"lastestMessageId"] = @(conversation.lastestMessageId);
    dict[@"lastestMessageDirection"] = @(conversation.lastestMessageDirection);
    dict[@"jsonDict"] = conversation.jsonDict;
    if ([conversation.lastestMessage isKindOfClass:[RCTextMessage class]]) {
        RCTextMessage *textMsg = (RCTextMessage *)conversation.lastestMessage;
        dict[@"msgType"] = @"text";
        dict[@"lastestMessage"] = textMsg.content;
        dict[@"extra"] = textMsg.extra;
    } else if ([conversation.lastestMessage isKindOfClass:[RCImageMessage class]]) {
        RCImageMessage *textMsg = (RCImageMessage *)conversation.lastestMessage;
        dict[@"msgType"] = @"image";
        dict[@"extra"] = textMsg.extra;
    } else if ([conversation.lastestMessage isKindOfClass:[RCVoiceMessage class]]) {
        RCVoiceMessage *textMsg = (RCVoiceMessage *)conversation.lastestMessage;
        dict[@"msgType"] = @"voice";
        dict[@"extra"] = textMsg.extra;
    }
    resolve(dict);
}

/*!
 创建讨论组
 @param discussionId                    讨论组ID
 @param discussionName                  讨论组名称
 @param creatorId                       创建者的用户ID
 @param conversationType                会话类型
 @param memberIdList                    讨论组成员的用户ID列表
 @param inviteStatus                    是否开放加人权限
 @param name            讨论组名称
 @param userIdList      用户ID的列表
 @param successBlock    创建讨论组成功的回调 [discussion:创建成功返回的讨论组对象]
 @param errorBlock      创建讨论组失败的回调 [status:创建失败的错误码]
 */
RCT_EXPORT_METHOD(createDiscussion:name
                  userIdList:(NSArray *)userIdList
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    
    void (^successBlock)(RCDiscussion *discussion);
    successBlock = ^(RCDiscussion *discussion) {
        NSMutableDictionary * dict = [NSMutableDictionary new];
        dict[@"discussionId"] = discussion.discussionId;
        dict[@"discussionName"] = discussion.discussionName;
        dict[@"creatorId"] = discussion.creatorId;
        dict[@"memberIdList"] = discussion.memberIdList;
        dict[@"inviteStatus"] = @((int)discussion.inviteStatus);
        resolve(dict);
    };
    
    void (^errorBlock)(RCErrorCode status);
    errorBlock = ^(RCErrorCode status) {
        reject(@"发送失败", @"发送失败", nil);
    };
    [[self getClient] createDiscussion:name userIdList:userIdList success:successBlock error:errorBlock];
}

/*!
 讨论组加人，将用户加入讨论组
 
 @param discussionId    讨论组ID
 @param userIdList      需要加入的用户ID列表
 @param successBlock    讨论组加人成功的回调 [discussion:讨论组加人成功返回的讨论组对象]
 @param errorBlock      讨论组加人失败的回调 [status:讨论组加人失败的错误码]
 
 @discussion 设置的讨论组名称长度不能超过40个字符，否则将会截断为前40个字符。
 */
RCT_EXPORT_METHOD(addMemberToDiscussion:discussionId
                  userIdList:(NSArray *)userIdList
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    
    void (^successBlock)(RCDiscussion *discussion);
    successBlock = ^(RCDiscussion *discussion) {
        NSMutableDictionary * dict = [NSMutableDictionary new];
        dict[@"discussionId"] = discussion.discussionId;
        dict[@"discussionName"] = discussion.discussionName;
        dict[@"creatorId"] = discussion.creatorId;
        dict[@"memberIdList"] = discussion.memberIdList;
        dict[@"inviteStatus"] = @((int)discussion.inviteStatus);
        resolve(dict);
    };
    
    void (^errorBlock)(RCErrorCode status);
    errorBlock = ^(RCErrorCode status) {
        reject(@"发送失败", @"发送失败", nil);
    };
    [[self getClient] addMemberToDiscussion:discussionId userIdList:userIdList success:successBlock error:errorBlock];
}

/*!
 讨论组踢人，将用户移出讨论组
 
 @param discussionId    讨论组ID
 @param userId          需要移出的用户ID
 @param successBlock    讨论组踢人成功的回调 [discussion:讨论组踢人成功返回的讨论组对象]
 @param errorBlock      讨论组踢人失败的回调 [status:讨论组踢人失败的错误码]
 
 @discussion 如果当前登陆用户不是此讨论组的创建者并且此讨论组没有开放加人权限，则会返回错误。
 
 @warning 不能使用此接口将自己移除，否则会返回错误。
 如果您需要退出该讨论组，可以使用-quitDiscussion:success:error:方法。
 */
RCT_EXPORT_METHOD(removeMemberFromDiscussion:discussionId
                  userId:(NSString *)userId
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    
    void (^successBlock)(RCDiscussion *discussion);
    successBlock = ^(RCDiscussion *discussion) {
        NSMutableDictionary * dict = [NSMutableDictionary new];
        dict[@"discussionId"] = discussion.discussionId;
        dict[@"discussionName"] = discussion.discussionName;
        dict[@"creatorId"] = discussion.creatorId;
        dict[@"memberIdList"] = discussion.memberIdList;
        dict[@"inviteStatus"] = @((int)discussion.inviteStatus);
        resolve(dict);
    };
    
    void (^errorBlock)(RCErrorCode status);
    errorBlock = ^(RCErrorCode status) {
        reject(@"发送失败", @"发送失败", nil);
    };
    [[self getClient] removeMemberFromDiscussion:discussionId userId:userId success:successBlock error:errorBlock];
}


/*!
 退出当前讨论组
 
 @param discussionId    讨论组ID
 @param successBlock    退出成功的回调 [discussion:退出成功返回的讨论组对象]
 @param errorBlock      退出失败的回调 [status:退出失败的错误码]
 */
RCT_EXPORT_METHOD(quitDiscussion:discussionId
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    
    void (^successBlock)(RCDiscussion *discussion);
    successBlock = ^(RCDiscussion *discussion) {
        NSMutableDictionary * dict = [NSMutableDictionary new];
        dict[@"discussionId"] = discussion.discussionId;
        dict[@"discussionName"] = discussion.discussionName;
        dict[@"creatorId"] = discussion.creatorId;
        dict[@"memberIdList"] = discussion.memberIdList;
        dict[@"inviteStatus"] = @((int)discussion.inviteStatus);
        resolve(dict);
    };
    
    void (^errorBlock)(RCErrorCode status);
    errorBlock = ^(RCErrorCode status) {
        reject(@"发送失败", @"发送失败", nil);
    };
    [[self getClient] quitDiscussion:discussionId success:successBlock error:errorBlock];
}

/*!
 获取讨论组的信息
 
 @param discussionId    需要获取信息的讨论组ID
 @param successBlock    获取讨论组信息成功的回调 [discussion:获取的讨论组信息]
 @param errorBlock      获取讨论组信息失败的回调 [status:获取讨论组信息失败的错误码]
 */
RCT_EXPORT_METHOD(getDiscussion:discussionId
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    
    void (^successBlock)(RCDiscussion *discussion);
    successBlock = ^(RCDiscussion *discussion) {
        NSMutableDictionary * dict = [NSMutableDictionary new];
        dict[@"discussionId"] = discussion.discussionId;
        dict[@"discussionName"] = discussion.discussionName;
        dict[@"creatorId"] = discussion.creatorId;
        dict[@"memberIdList"] = discussion.memberIdList;
        dict[@"inviteStatus"] = @((int)discussion.inviteStatus);
        resolve(dict);
    };
    
    void (^errorBlock)(RCErrorCode status);
    errorBlock = ^(RCErrorCode status) {
        reject(@"发送失败", @"发送失败", nil);
    };
    [[self getClient] getDiscussion:discussionId success:successBlock error:errorBlock];
}

/*!
 设置讨论组名称
 
 @param targetId                需要设置的讨论组ID
 @param discussionName          需要设置的讨论组名称，discussionName长度<=40
 @param successBlock            设置成功的回调
 @param errorBlock              设置失败的回调 [status:设置失败的错误码]
 
 @discussion 设置的讨论组名称长度不能超过40个字符，否则将会截断为前40个字符。
 */
RCT_EXPORT_METHOD(setDiscussionName:discussionId
                  name:(NSString *)discussionName
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    
    void (^successBlock)(RCDiscussion *discussion);
    successBlock = ^(RCDiscussion *discussion) {
        NSMutableDictionary * dict = [NSMutableDictionary new];
        dict[@"discussionId"] = discussion.discussionId;
        dict[@"discussionName"] = discussion.discussionName;
        dict[@"creatorId"] = discussion.creatorId;
        dict[@"memberIdList"] = discussion.memberIdList;
        dict[@"inviteStatus"] = @((int)discussion.inviteStatus);
        resolve(dict);
    };
    
    void (^errorBlock)(RCErrorCode status);
    errorBlock = ^(RCErrorCode status) {
        reject(@"发送失败", @"发送失败", nil);
    };
    [[self getClient] setDiscussionName:discussionId name:discussionName success:successBlock error:errorBlock];
}

/*!
 设置讨论组是否开放加人权限
 
 @param targetId        讨论组ID
 @param isOpen          是否开放加人权限
 @param successBlock    设置成功的回调
 @param errorBlock      设置失败的回调[status:设置失败的错误码]
 
 @discussion 讨论组默认开放加人权限，即所有成员都可以加人。
 如果关闭加人权限之后，只有讨论组的创建者有加人权限。
 */
RCT_EXPORT_METHOD(setDiscussionInviteStatus:discussionId
                  isOpen:(BOOL)isOpen
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    
    void (^successBlock)();
    successBlock = ^() {
        resolve(@"权限开启");
    };
    
    void (^errorBlock)(RCErrorCode status);
    errorBlock = ^(RCErrorCode status) {
        reject(@"发送失败", @"发送失败", nil);
    };
    [[self getClient] setDiscussionInviteStatus:discussionId isOpen:isOpen success:successBlock error:errorBlock];
}

//获取本地存储的会话列表
RCT_REMAP_METHOD(getConversationList,
                 resolve:(RCTPromiseResolveBlock)resolve
                 reject:(RCTPromiseRejectBlock)reject) {
    
    NSArray *conversationList = [[self getClient] getConversationList:@[@(ConversationType_PRIVATE),@(ConversationType_GROUP)]];
    if(conversationList.count > 0){
        NSMutableArray * array = [NSMutableArray new];
        for  (RCConversation * conversation in conversationList) {
            NSMutableDictionary * dict = [NSMutableDictionary new];
            dict[@"conversationType"] = @((unsigned long)conversation.conversationType);
            dict[@"targetId"] = conversation.targetId;
            dict[@"conversationTitle"] = conversation.conversationTitle;
            dict[@"unreadMessageCount"] = @(conversation.unreadMessageCount);
            dict[@"receivedTime"] = @((long long)conversation.receivedTime);
            dict[@"sentTime"] = @((long long)conversation.sentTime);
            dict[@"senderUserId"] = conversation.senderUserId;
            dict[@"lastestMessageId"] = @(conversation.lastestMessageId);
            dict[@"lastestMessageDirection"] = @(conversation.lastestMessageDirection);
            dict[@"jsonDict"] = conversation.jsonDict;
            if ([conversation.lastestMessage isKindOfClass:[RCTextMessage class]]) {
                RCTextMessage *textMsg = (RCTextMessage *)conversation.lastestMessage;
                dict[@"msgType"] = @"text";
                dict[@"lastestMessage"] = textMsg.content;
                dict[@"extra"] = textMsg.extra;
            } else if ([conversation.lastestMessage isKindOfClass:[RCImageMessage class]]) {
                RCImageMessage *textMsg = (RCImageMessage *)conversation.lastestMessage;
                dict[@"msgType"] = @"image";
                dict[@"extra"] = textMsg.extra;
            } else if ([conversation.lastestMessage isKindOfClass:[RCVoiceMessage class]]) {
                RCVoiceMessage *textMsg = (RCVoiceMessage *)conversation.lastestMessage;
                dict[@"msgType"] = @"voice";
                dict[@"extra"] = textMsg.extra;
            }
            
            [array addObject:dict];
        }
        NSLog(@"conversationList === %@",array);
        resolve(array);
    }else{
        NSLog(@"=== 读取失败 === ");
        reject(@"读取失败", @"读取失败", nil);
    }
}


RCT_REMAP_METHOD(getLatestMessages,
                 type:(int)type
                 targetId:(NSString *)targetId
                 count:(int)count
                 resolve:(RCTPromiseResolveBlock)resolve
                 reject:(RCTPromiseRejectBlock)reject) {
    
    RCConversationType conversationType;
    switch (type) {
        case 1:
            conversationType = ConversationType_PRIVATE;
            break;
        case 3:
            conversationType = ConversationType_GROUP;
            break;
            
        default:
            conversationType = ConversationType_PRIVATE;
            break;
    }
    
    NSArray * messageList = [[self getClient] getLatestMessages:conversationType targetId:targetId count:count];
    if(messageList){
        NSMutableArray * array = [NSMutableArray new];
        for (RCMessage * message in messageList) {
            NSMutableDictionary * dict = [NSMutableDictionary new];
            dict[@"conversationType"] = @((unsigned long)message.conversationType);
            dict[@"targetId"] = message.targetId;
            dict[@"messageId"] = @(message.messageId);
            dict[@"receivedTime"] = @((long long)message.receivedTime);
            dict[@"sentTime"] = @((long long)message.sentTime);
            dict[@"senderUserId"] = message.senderUserId;
            dict[@"messageUId"] = message.messageUId;
            dict[@"messageDirection"] = @(message.messageDirection);
            
            if([message.content isKindOfClass:[RCTextMessage class]]){
                RCTextMessage *textMsg = (RCTextMessage *)message.content;
                dict[@"type"] = @"text";
                dict[@"content"] = textMsg.content;
                dict[@"extra"] = textMsg.extra;
            }
            else if ([message.content isKindOfClass:[RCImageMessage class]]){
                RCImageMessage *imageMsg = (RCImageMessage *)message.content;
                dict[@"type"] = @"image";
                dict[@"imageUrl"] = imageMsg.imageUrl;
                dict[@"extra"] = imageMsg.extra;
            } else if ([message.content isKindOfClass:[RCRichContentMessage class]]) {
                RCRichContentMessage *imageMsg = (RCRichContentMessage *)message.content;
                dict[@"msgType"] = @"imageText";
                dict[@"imageUrl"] = imageMsg.imageURL;
                dict[@"extra"] = imageMsg.extra;
            }
            else if ([message.content isKindOfClass:[RCVoiceMessage class]]){
                RCVoiceMessage *voiceMsg = (RCVoiceMessage *)message.content;
                dict[@"type"] = @"voice";
                dict[@"wavAudioData"] = [self saveWavAudioDataToSandbox:voiceMsg.wavAudioData messageId:message.messageId];
                dict[@"duration"] = @(voiceMsg.duration);
                dict[@"extra"] = voiceMsg.extra;
            }
            [array addObject:dict];
        }
        NSLog(@"MessagesList === %@",array);
        resolve(array);
        
    }
    else{
        reject(@"读取失败", @"读取失败", nil);
    }
}

- (NSString *)saveWavAudioDataToSandbox:(NSData *)data messageId:(NSInteger)msgId{
    
    NSFileManager * fileManager = [NSFileManager defaultManager];
    
    NSString * documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    
    NSString * directoryPath = [documentPath stringByAppendingString:@"/ChatMessage"];
    
    if(![fileManager fileExistsAtPath:directoryPath]){
        
        [fileManager createDirectoryAtPath:directoryPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    
    NSString * filePath = [directoryPath stringByAppendingString:[NSString stringWithFormat:@"/%ld.wav",msgId]];
    
    [fileManager createFileAtPath:filePath contents:data attributes:nil];
    
    return filePath;
}

#pragma mark  RongCloud  SearchMessagesFromLocal

RCT_REMAP_METHOD(searchConversations,
                 keyword:(NSString *)keyword
                 resolve:(RCTPromiseResolveBlock)resolve
                 reject:(RCTPromiseRejectBlock)reject) {
    
    NSArray *SearchResult = [[self getClient] searchConversations:@[@(ConversationType_PRIVATE),@(ConversationType_GROUP)] messageType:@[[RCTextMessage getObjectName]] keyword:keyword];
    
    
    if(SearchResult.count > 0){
        NSMutableArray * array = [NSMutableArray new];
        for  (RCSearchConversationResult * result in SearchResult) {
            NSMutableDictionary * dict = [NSMutableDictionary new];
            dict[@"conversationType"] = @((unsigned long)result.conversation.conversationType);
            dict[@"targetId"] = result.conversation.targetId;
            dict[@"conversationTitle"] = result.conversation.conversationTitle;
            dict[@"unreadMessageCount"] = @(result.conversation.unreadMessageCount);
            dict[@"receivedTime"] = @((long long)result.conversation.receivedTime);
            dict[@"sentTime"] = @((long long)result.conversation.sentTime);
            dict[@"senderUserId"] = result.conversation.senderUserId;
            dict[@"lastestMessageId"] = @(result.conversation.lastestMessageId);
            dict[@"lastestMessageDirection"] = @(result.conversation.lastestMessageDirection);
            dict[@"jsonDict"] = result.conversation.jsonDict;
            if ([result.conversation.lastestMessage isKindOfClass:[RCTextMessage class]]) {
                RCTextMessage *textMsg = (RCTextMessage *)result.conversation.lastestMessage;
                dict[@"msgType"] = @"text";
                dict[@"lastestMessage"] = textMsg.content;
            } else if ([result.conversation.lastestMessage isKindOfClass:[RCImageMessage class]]) {
                dict[@"msgType"] = @"image";
            }  else if ([result.conversation.lastestMessage isKindOfClass:[RCRichContentMessage class]]) {
                dict[@"msgType"] = @"imageText";
            }else if ([result.conversation.lastestMessage isKindOfClass:[RCVoiceMessage class]]) {
                dict[@"msgType"] = @"voice";
            }
            
            [array addObject:dict];
        }
        NSLog(@"SearchResultList === %@",array);
        resolve(array);
    }else{
        NSLog(@"=== 读取失败 === ");
        reject(@"读取失败", @"读取失败", nil);
    }
}

#pragma mark  RongCloud  Send Text / Image  Messages

RCT_EXPORT_METHOD(sendTextMessage:(int)type
                  targetId:(NSString *)targetId
                  targetName:(NSString *)targetName
                  content:(NSString *)content
                  pushContent:(NSString *) pushContent
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    
    RCTextMessage *messageContent = [RCTextMessage messageWithContent:content];
    messageContent.extra=targetName;
    [self sendMessage:type messageType:@"text" targetId:targetId content:messageContent pushContent:pushContent resolve:resolve reject:reject];
    
    
}

/*!
 获取会话中，从指定消息之前、指定数量的、指定消息类型的最新消息实体
 
 @param conversationType    会话类型
 @param targetId            目标会话ID
 @param objectName          消息内容的类型名
 @param oldestMessageId     截止的消息ID
 @param count               需要获取的消息数量
 @return                    消息实体RCMessage对象列表
 
 @discussion 此方法会获取该会话中，oldestMessageId之前的、指定数量和消息类型的最新消息实体，返回的消息实体按照时间从新到旧排列。
 返回的消息中不包含oldestMessageId对应的那条消息，如果会话中的消息数量小于参数count的值，会将该会话中的所有消息返回。
 如：
 oldestMessageId为10，count为2，会返回messageId为9和8的RCMessage对象列表。
 */

RCT_EXPORT_METHOD(getHistoryMessages:(int)conversationType
                  targetId:(NSString *)targetId
                  objectName:(NSString *)objectName
                  oldestMessageId:(long)oldestMessageId
                  count:(int)count
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject
                  ){
    NSArray *messageList = [[NSArray alloc] init];
    if([objectName isEqualToString:@""]){
        messageList=  [[self getClient] getHistoryMessages:conversationType targetId:targetId oldestMessageId:oldestMessageId count:count];
    }else{
        messageList=  [[self getClient] getHistoryMessages:conversationType targetId:targetId objectName:objectName oldestMessageId:oldestMessageId count:count];
    }
    if(messageList){
        NSMutableArray * array = [NSMutableArray new];
        for (RCMessage * message in messageList) {
            NSMutableDictionary * dict = [NSMutableDictionary new];
            dict[@"conversationType"] = @((unsigned long)message.conversationType);
            dict[@"targetId"] = message.targetId;
            dict[@"messageId"] = @(message.messageId);
            dict[@"receivedTime"] = @((long long)message.receivedTime);
            dict[@"sentTime"] = @((long long)message.sentTime);
            dict[@"senderUserId"] = message.senderUserId;
            dict[@"messageUId"] = message.messageUId;
            dict[@"messageDirection"] = @(message.messageDirection);
            
            if([message.content isKindOfClass:[RCTextMessage class]]){
                RCTextMessage *textMsg = (RCTextMessage *)message.content;
                dict[@"type"] = @"text";
                dict[@"content"] = textMsg.content;
                dict[@"extra"] = textMsg.extra;
            }
            else if ([message.content isKindOfClass:[RCImageMessage class]]){
                RCImageMessage *imageMsg = (RCImageMessage *)message.content;
                dict[@"type"] = @"image";
                dict[@"imageUrl"] = imageMsg.imageUrl;
                dict[@"extra"] = imageMsg.extra;
            }
            else if ([message.content isKindOfClass:[RCVoiceMessage class]]){
                RCVoiceMessage *voiceMsg = (RCVoiceMessage *)message.content;
                dict[@"type"] = @"voice";
                dict[@"wavAudioData"] = [self saveWavAudioDataToSandbox:voiceMsg.wavAudioData messageId:message.messageId];
                dict[@"duration"] = @(voiceMsg.duration);
                dict[@"extra"] = voiceMsg.extra;
            }
            [array addObject:dict];
        }
        NSLog(@"MessagesList === %@",array);
        resolve(array);
        
    }
    else{
        reject(@"读取失败", @"读取失败", nil);
    }
    resolve([NSString stringWithFormat:@"%d",count]);
}

/*!
 获取某个会话内的未读消息数
 
 @param conversationType    会话类型
 @param targetId            会话目标ID
 @return                    该会话内的未读消息数
 */
RCT_EXPORT_METHOD(getUnreadCount:(int)type
                  targetId:(NSString *)targetId
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject
                  ){
    int count =  [[self getClient] getUnreadCount:type targetId:targetId];
    resolve([NSString stringWithFormat:@"%d",count]);
}

/*!
 获取某个类型的会话中所有的未读消息数
 
 @param conversationTypes   会话类型的数组
 @return                    该类型的会话中所有的未读消息数
 */
RCT_EXPORT_METHOD(getUnreadCountAllTypes:(NSArray *)types
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject
                  ){
    int count =  [[self getClient] getUnreadCount:types];
    resolve([NSString stringWithFormat:@"%d",count]);
}


RCT_EXPORT_METHOD(sendImageMessage:(int)type
                  targetId:(NSString *)targetId
                  targetName:(NSString *)targetName
                  content:(NSString *)imageUrl
                  pushContent:(NSString *) pushContent
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    
    if([imageUrl rangeOfString:@"assets-library"].location == NSNotFound){
        RCImageMessage *imageMessage = [RCImageMessage messageWithImageURI:imageUrl];
        imageMessage.extra=targetName;
        [self sendMessage:type messageType:@"image" targetId:targetId content:imageMessage pushContent:pushContent resolve:resolve reject:reject];
    }
    else{
        [self sendImageMessageWithType:type targetId:targetId targetName:targetName ImageUrl:imageUrl pushContent:pushContent resolve:resolve reject:reject];
    }
}

- (void)sendImageMessageWithType:(int)type
                        targetId:(NSString *)targetId
                      targetName:(NSString *)targetName
                        ImageUrl:(NSString *)imageUrl
                     pushContent:(NSString *)pushContent
                         resolve:(RCTPromiseResolveBlock)resolve
                          reject:(RCTPromiseRejectBlock)reject{
    
    ALAssetsLibrary   *lib = [[ALAssetsLibrary alloc] init];
    
    [lib assetForURL:[NSURL URLWithString:imageUrl] resultBlock:^(ALAsset *asset) {
        //在这里使用asset来获取图片
        ALAssetRepresentation *assetRep = [asset defaultRepresentation];
        CGImageRef imgRef = [assetRep fullResolutionImage];
        UIImage * image = [UIImage imageWithCGImage:imgRef
                                              scale:assetRep.scale
                                        orientation:(UIImageOrientation)assetRep.orientation];
        UIImage * scaledImage = [self scaleImageWithImage:image toSize:CGSizeMake(960, 960)]; // 融云推荐使用的大图尺寸为：960 x 960 像素
        
        RCImageMessage *imageMessage = [RCImageMessage messageWithImage:scaledImage];
        imageMessage.extra=targetName;
        [self sendMessage:type messageType:@"image" targetId:targetId content:imageMessage pushContent:pushContent resolve:resolve reject:reject];
        
    } failureBlock:^(NSError *error) {
        reject(@"Could not find the image",@"Could not find the image",nil);
    }];
    
}

//等比例缩小
-(UIImage *)scaleImageWithImage:(UIImage *)image toSize:(CGSize)size
{
    CGFloat width = CGImageGetWidth(image.CGImage);
    CGFloat height = CGImageGetHeight(image.CGImage);
    
    if(width < size.width && height < size.height){
        return image;
    }
    
    float verticalRadio = height/size.height;
    float horizontalRadio = width/size.width;
    
    float radio = verticalRadio > horizontalRadio ? verticalRadio : horizontalRadio;
    
    width = width/radio;
    height = height/radio;
    
    // 创建一个bitmap的context
    // 并把它设置成为当前正在使用的context
    UIGraphicsBeginImageContext(CGSizeMake(width, height));
    
    // 绘制改变大小的图片
    [image drawInRect:CGRectMake(0, 0, width, height)];
    
    // 从当前context中创建一个改变大小后的图片
    UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    
    // 使当前的context出堆栈
    UIGraphicsEndImageContext();
    
    // 返回新的改变大小后的图片
    return scaledImage;
}

#pragma mark  RongCloud  Send Voice Messages
/**
 *  录音开始
 */
RCT_EXPORT_METHOD(voiceBtnPressIn:(int)type
                  targetId:(NSString *)targetId
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    NSLog(@"开始录音");
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        AVAudioSession *session =[AVAudioSession sharedInstance];
        NSError *sessionError;
        [session setCategory:AVAudioSessionCategoryPlayAndRecord error:&sessionError];
        
        if (session == nil) {
            NSLog(@"Error creating session: %@",[sessionError description]);
        }else{
            [session setActive:YES error:nil];
        }
        
        self.session = session;
        
        //1.获取沙盒地址
        NSString * filePath = [self getSandboxFilePath];
        
        //2.获取文件路径
        self.recordFileUrl = [NSURL fileURLWithPath:filePath];
        
        //设置参数
        //    NSDictionary *recordSetting = [[NSDictionary alloc] initWithObjectsAndKeys:
        //                                   //采样率  8000/11025/22050/44100/96000（影响音频的质量）
        //                                   [NSNumber numberWithFloat: 8000.0],AVSampleRateKey,
        //                                   // 音频格式
        //                                   [NSNumber numberWithInt: kAudioFormatLinearPCM],AVFormatIDKey,
        //                                   //采样位数  8、16、24、32 默认为16
        //                                   [NSNumber numberWithInt:16],AVLinearPCMBitDepthKey,
        //                                   // 音频通道数 1 或 2
        //                                   [NSNumber numberWithInt: 1], AVNumberOfChannelsKey,
        //                                   //录音质量
        //                                   [NSNumber numberWithInt:AVAudioQualityHigh],AVEncoderAudioQualityKey,
        //                                   nil];
        NSDictionary * recordSetting = @{AVFormatIDKey: @(kAudioFormatLinearPCM),
                                         AVSampleRateKey: @8000.00f,
                                         AVNumberOfChannelsKey: @1,
                                         AVLinearPCMBitDepthKey: @16,
                                         AVLinearPCMIsNonInterleaved: @NO,
                                         AVLinearPCMIsFloatKey: @NO,
                                         AVLinearPCMIsBigEndianKey: @NO};   //RongCloud 推荐参数
        
        
        _recorder = [[AVAudioRecorder alloc] initWithURL:self.recordFileUrl settings:recordSetting error:nil];
        
        if (_recorder) {
            
            @try{
                
                _startDate = [NSDate date];
                
                _recorder.meteringEnabled = YES;
                [_recorder prepareToRecord];
                [_recorder record];
                
                _isSend = NO;
                _duration = 0;
                
                _longTimer = [NSTimer scheduledTimerWithTimeInterval:59.0 repeats:NO block:^(NSTimer * _Nonnull timer) {
                    if(!_isSend){
                        [self stopRecord:type targetId:targetId resolve:resolve reject:reject];
                    }
                }];
            }
            @catch(NSException *exception) {
                NSLog(@"exception:%@", exception);
            }
            @finally {
                
            }
        }else{
            NSLog(@"音频格式和文件存储格式不匹配,无法初始化Recorder");
        }
    });
}

/**
 *  取消录音
 */
RCT_EXPORT_METHOD(voiceBtnPressCancel:(int)type
                  targetId:(NSString *)targetId
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [self removeTimer];
        NSLog(@"取消录音");
        
        _isSend = NO;
        if ([self.recorder isRecording]) {
            [self.recorder stop];
            self.recorder = nil;
            
            resolve(@"已取消");
        }else{
            reject(@"没有正在录音的资源",@"没有正在录音的资源",nil);
        }
    });
}

/**
 *  录音结束
 */
RCT_EXPORT_METHOD(voiceBtnPressOut:(int)type
                  targetId:(NSString *)targetId
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if(!_isSend){
            [self stopRecord:type targetId:targetId resolve:resolve reject:reject];
        }
    });
}

- (void)stopRecord:(int)type
          targetId:(NSString *)targetId
           resolve:(RCTPromiseResolveBlock)resolve
            reject:(RCTPromiseRejectBlock)reject{
    
    [self removeTimer];
    NSLog(@"停止录音");
    
    if ([self.recorder isRecording]) {
        [self.recorder stop];
        self.recorder = nil;
    }
    
    _isSend = YES;
    
    _endDate = [NSDate date];
    
    NSTimeInterval dataLong = [_endDate timeIntervalSinceDate:_startDate];
    
    if(dataLong < 1.0){
        reject(@"-500",@"-500",nil);
    }else{
        
        _duration = (NSInteger)roundf(dataLong);
        
        NSData * audioData = [NSData dataWithContentsOfURL:self.recordFileUrl];
        [self sendVoiceMessage:type targetId:targetId content:audioData duration:_duration pushContent:@"语音" resolve:resolve reject:reject];
        
        //发送完录音后，删除本地录音（融云会自动保存录音）
        NSString * filePath = self.recordFileUrl.absoluteString;
        NSFileManager * fileManager = [NSFileManager defaultManager];
        
        if(![fileManager fileExistsAtPath:filePath]){
            
            [fileManager removeItemAtPath:filePath error:nil];
        }
    }
}

- (NSString *)getSandboxFilePath{
    
    NSFileManager * fileManager = [NSFileManager defaultManager];
    
    NSString * documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    
    NSString * directoryPath = [documentPath stringByAppendingString:@"/ChatMessage"];
    
    if(![fileManager fileExistsAtPath:directoryPath]){
        
        [fileManager createDirectoryAtPath:directoryPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyyMMddHHmmss"];
    NSString * timeString = [dateFormatter stringFromDate:[NSDate date]];
    
    NSString * filePath = [directoryPath stringByAppendingString:[NSString stringWithFormat:@"/%@.wav",timeString]];
    
    [fileManager createFileAtPath:filePath contents:nil attributes:nil];
    
    return filePath;
}


// 移除定时器
- (void)removeTimer
{
    if(_longTimer){
        [_longTimer invalidate];
        _longTimer = nil;
    }
}

- (void)sendVoiceMessage:(int)type
                targetId:(NSString *)targetId
                 content:(NSData *)voiceData
                duration:(NSInteger )duration
             pushContent:(NSString *) pushContent
                 resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject {
    
    RCVoiceMessage *rcVoiceMessage = [RCVoiceMessage messageWithAudio:voiceData duration:duration];
    [self sendMessage:type messageType:@"voice" targetId:targetId content:rcVoiceMessage pushContent:pushContent resolve:resolve reject:reject];
    
}

#pragma mark  RongCloud  Play Voice Messages

RCT_EXPORT_METHOD(audioPlayStart:(NSString *)filePath
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject){
    
    self.session =[AVAudioSession sharedInstance];
    NSError *sessionError;
    [self.session setCategory:AVAudioSessionCategoryPlayback error:&sessionError];
    [self.session setActive:YES error:nil];
    
    if(_player){
        [_player stop];
        _player = nil;
    }
    
    NSURL *audioUrl = [NSURL fileURLWithPath:filePath];
    NSError *playerError;
    _player = [[AVAudioPlayer alloc] initWithContentsOfURL:audioUrl error:&playerError];
    
    if (_player == nil)
    {
        NSLog(@"fail to play audio :(");
        reject(@"播放失败，请重试！",@"播放失败，请重试！",nil);
        return;
    }
    
    [_player setNumberOfLoops:0];
    [_player prepareToPlay];
    [_player play];
    resolve(@"正在播放");
}


RCT_REMAP_METHOD(audioPlayStop,
                 resolve:(RCTPromiseResolveBlock)resolve
                 rejecte:(RCTPromiseRejectBlock)reject){
    if(_player && [_player isPlaying]){
        [_player stop];
        resolve(@"已停止");
    }else{
        reject(@"没有播放的资源",@"没有播放的资源",nil);
    }
}

#pragma mark  RongCloud  GetSDKVersion  and   Disconnect

RCT_REMAP_METHOD(getSDKVersion,
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject) {
    NSString* version = [[self getClient] getSDKVersion];
    resolve(version);
}

RCT_EXPORT_METHOD(disconnect:(BOOL)isReceivePush) {
    [[self getClient] disconnect:isReceivePush];
}


#pragma mark  RongCloud  SDK methods

-(RCIMClient *) getClient {
    return [RCIMClient sharedRCIMClient];
}

- (void)setupPushNotificationsDeviceToken{
    
    NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
    NSString * deviceToken = [userDefaults objectForKey:@"RongPushNotificationsDeviceToken"];
    if(deviceToken && deviceToken.length > 0){
        NSLog(@"RongCloud setDeviceToken:%@",deviceToken);
        [[self getClient] setDeviceToken:deviceToken];
    }else{
        dispatch_async(dispatch_get_main_queue(), ^{
            
            NSTimer * tokenTimer = [NSTimer timerWithTimeInterval:1.0 target:self selector:@selector(refreshDeviceToken:) userInfo:nil repeats:YES]; // 需要加入手动RunLoop，需要注意的是在NSTimer工作期间self是被强引用的
            [[NSRunLoop currentRunLoop] addTimer:tokenTimer forMode:NSRunLoopCommonModes];
        });
    }
}

- (void)refreshDeviceToken:(NSTimer *)timer{
    
    NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
    NSString * deviceToken = [userDefaults objectForKey:@"RongPushNotificationsDeviceToken"];
    if(deviceToken && deviceToken.length > 0){
        NSLog(@"RongCloud setDeviceToken:%@",deviceToken);
        [[self getClient] setDeviceToken:deviceToken];
        [timer invalidate];
        timer = nil;
    }
}


-(void)sendMessage:(int)type
       messageType:(NSString *)messageType
          targetId:(NSString *)targetId
           content:(RCMessageContent *)content
       pushContent:(NSString *) pushContent
           resolve:(RCTPromiseResolveBlock)resolve
            reject:(RCTPromiseRejectBlock)reject {
    
    RCConversationType conversationType;
    switch (type) {
        case 1:
            conversationType = ConversationType_PRIVATE;
            break;
        case 3:
            conversationType = ConversationType_GROUP;
            break;
            
        default:
            conversationType = ConversationType_PRIVATE;
            break;
    }
    
    void (^successBlock)(long messageId);
    successBlock = ^(long messageId) {
        NSString* messageid = [NSString stringWithFormat:@"%ld",messageId];
        resolve(messageid);
    };
    
    void (^errorBlock)(RCErrorCode nErrorCode , long messageId);
    errorBlock = ^(RCErrorCode nErrorCode , long messageId) {
        reject(@"发送失败", @"发送失败", nil);
    };
    
    if ([messageType isEqualToString:@"image"]){  //图片和文件消息使用sendMediaMessage方法（此方法会将图片上传至融云服务器）
        [[self getClient] sendMediaMessage:conversationType targetId:targetId content:content pushContent:pushContent pushData:nil progress:nil success:successBlock error:errorBlock cancel:nil];
    }else{  //文本和语音使用sendMessage方法（若使用本方法发送图片消息，则需要上传图片到自己的服务器后把图片地址放到图片消息内）
        [[self getClient] sendMessage:conversationType targetId:targetId content:content pushContent:pushContent pushData:nil success:successBlock error:errorBlock];
    }
    
}

-(void)onReceived:(RCMessage *)message
             left:(int)nLeft
           object:(id)object {
    
    NSLog(@"onRongCloudMessageReceived");
    
    NSMutableDictionary *body = [self getEmptyBody];
    NSMutableDictionary *_message = [self getEmptyBody];
    
    _message[@"targetId"] = message.targetId;
    _message[@"senderUserId"] = message.senderUserId;
    _message[@"messageId"] = [NSString stringWithFormat:@"%ld",message.messageId];
    _message[@"sentTime"] = @((long long)message.sentTime);
    _message[@"receivedTime"] = @((long long)message.receivedTime);
    _message[@"senderUserId"] = message.senderUserId;
    _message[@"conversationType"] = @((unsigned long)message.conversationType);
    _message[@"messageDirection"] = @(message.messageDirection);
    _message[@"objectName"] = message.objectName;
    _message[@"extra"] = message.extra;
    
    if ([message.content isMemberOfClass:[RCTextMessage class]]) {
        RCTextMessage *textMessage = (RCTextMessage *)message.content;
        _message[@"type"] = @"text";
        _message[@"content"] = textMessage.content;
        _message[@"extra"] = textMessage.extra;
    }
    else if([message.content isMemberOfClass:[RCImageMessage class]]) {
        RCImageMessage *imageMessage = (RCImageMessage *)message.content;
        _message[@"type"] = @"image";
        _message[@"imageUrl"] = imageMessage.imageUrl;
        _message[@"thumbnailImage"] = imageMessage.thumbnailImage;
        _message[@"extra"] = imageMessage.extra;
    }
    else if ([message.content isMemberOfClass:[RCVoiceMessage class]]) {
        RCVoiceMessage *voiceMessage = (RCVoiceMessage *)message.content;
        _message[@"type"] = @"voice";
        _message[@"wavAudioData"] = voiceMessage.wavAudioData;
        _message[@"duration"] = @(voiceMessage.duration);
        _message[@"extra"] = voiceMessage.extra;
    }
    
    
    body[@"left"] = [NSString stringWithFormat:@"%d",nLeft];
    body[@"message"] = _message;
    body[@"errcode"] = @"0";
    
    [self sendEventWithName:@"onRongMessageReceived" body:body];
}

//监听连接状态
-(void)onConnectionStatusChanged:(RCConnectionStatus)status{
    NSMutableDictionary *body = [self getEmptyBody];
    body[@"status"] = [NSString stringWithFormat:@"%ld",status];
    [self sendEventWithName:@"onRongConnectionStatus" body:body];
}

// RCIMClient Class

/*!
 获取当前SDK的连接状态
 @return 当前SDK的连接状态
 */

RCT_EXPORT_METHOD(getConnectionStatus:(NSString *)type
                  resolve:(RCTPromiseResolveBlock)resolve
                  rejecte:(RCTPromiseRejectBlock)reject) {
    RCConnectionStatus status = [[self getClient] getConnectionStatus];
    resolve([NSString stringWithFormat:@"%ld",status]);
}

//监听键盘输入
- (void)onTypingStatusChanged:(RCConversationType)conversationType
                     targetId:(NSString *)targetId
                       status:(NSArray *)userTypingStatusList{
    
}

-(NSMutableDictionary *)getEmptyBody {
    NSMutableDictionary *body = @{}.mutableCopy;
    return body;
}


@end

