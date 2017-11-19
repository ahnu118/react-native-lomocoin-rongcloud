'use strict';
import {
    NativeModules,
    DeviceEventEmitter,
    NativeEventEmitter
}
    from 'react-native';

const RongCloudIMLib = NativeModules.RongCloudIMLibModule;

var _onRongCloudMessageReceived = function (resp) {
    console.log("融云接受消息:" + JSON.stringify(resp));
}

var _onRongCloudConnectionStatus = function(resp) {
    console.log('连接状态:'+resp)
}

DeviceEventEmitter.addListener('onRongMessageReceived', (resp) => {
    typeof (_onRongCloudMessageReceived) === 'function' && _onRongCloudMessageReceived(resp);
});

DeviceEventEmitter.addListener('onRongConnectionStatus', (resp) => {
    typeof (_onRongCloudConnectionStatus) === 'function' && _onRongCloudConnectionStatus(resp);
});

const RongCloudIMLibEmitter = new NativeEventEmitter(RongCloudIMLib);

const subscription = RongCloudIMLibEmitter.addListener(
    'onRongMessageReceived',
    (resp) => {
        typeof (_onRongCloudMessageReceived) === 'function' && _onRongCloudMessageReceived(resp);
    }
);

const connectionSubscription = RongCloudIMLibEmitter.addListener(
    'onRongConnectionStatus',
    (resp) => {
        typeof (_onRongCloudConnectionStatus) === 'function' && _onRongCloudConnectionStatus(resp);
    }
);


const ConversationType = {
    PRIVATE: 1,
    DISCUSSION: 2,
    GROUP: 3,
    CHATROOM: 4,
    CUSTOMER_SERVICE: 5,
    SYSTEM: 6,
    APP_PUBLIC_SERVICE: 7,
    PUBLIC_SERVICE: 8,
    PUSHSERVICE: 9
};

export default {
    ConversationType: ConversationType,
    onConnectionStatus(callback){
        _onRongCloudConnectionStatus = callback;
    },
    onReceived(callback) {
        _onRongCloudMessageReceived = callback;
    },
    getConnectionStatus(){
        return RongCloudIMLib.getConnectionStatus('');
    },
    initWithAppKey(appKey) {
        return RongCloudIMLib.initWithAppKey(appKey);
    },
    connectWithToken(token) {
        return RongCloudIMLib.connectWithToken(token);
    },
    clearUnreadMessage(conversationType, targetId){
        return RongCloudIMLib.clearUnreadMessage(conversationType, targetId);
    },
    clearMessages(conversationType, targetId){//删除某个会话中的所有消息
        return RongCloudIMLib.clearMessages(conversationType, targetId);
    },
    removeConversation(conversationType, targetId){//此方法会从本地存储中删除该会话，但是不会删除会话中的消息。
        return RongCloudIMLib.removeConversation(conversationType, targetId);
    },
    setConversationToTop(conversationType, targetId, isTop){//设置会话的置顶状态
        return RongCloudIMLib.setConversationToTop(conversationType, targetId, isTop);
    },
    sendReadReceiptMessage(conversationType, targetId, timestamp){//发送某个会话中消息阅读的回执
        return RongCloudIMLib.sendReadReceiptMessage(conversationType, targetId, timestamp);
    },
    getUnreadCount(conversationType, targetId){//获取未读消息数
        return RongCloudIMLib.getUnreadCount(conversationType, targetId);
    },
    getUnreadCountAllTypes(types){
        return RongCloudIMLib.getUnreadCountAllTypes(types);
    },
    createDiscussion(name, userIdList){//创建讨论组 name群名
        return RongCloudIMLib.createDiscussion(name, userIdList);
    },
    addMemberToDiscussion(discussionId, userIdList){//讨论组加人，将用户加入讨论组
        return RongCloudIMLib.addMemberToDiscussion(discussionId, userIdList);
    },
    removeMemberFromDiscussion(discussionId,userId){//讨论组踢人，将用户移出讨论组
        return RongCloudIMLib.removeMemberFromDiscussion(discussionId,userId);
    },
    quitDiscussion(discussionId){//退出当前讨论组
        return RongCloudIMLib.quitDiscussion(discussionId);
    },
    getDiscussion(discussionId){//获取讨论组的信息
        return RongCloudIMLib.quitDiscussion(discussionId);
    },
    setDiscussionName(discussionId, discussionName){//设置讨论组名称
        return RongCloudIMLib.setDiscussionName(discussionId, discussionName);
    },
    setDiscussionInviteStatus(discussionId, isOpen){//设置讨论组是否开放加人权限
        return RongCloudIMLib.setDiscussionInviteStatus(discussionId, isOpen);
    },
    searchConversations(keyword) {
        return RongCloudIMLib.searchConversations(keyword);
    },
    getConversationList() {//获取本地存储的会话列表
        return RongCloudIMLib.getConversationList();
    },
    getConversation(conversationType, targetId) {//获取单个会话数据
        return RongCloudIMLib.getConversationList(conversationType, targetId);
    },
    getLatestMessages(type, targetId, count) {
        return RongCloudIMLib.getLatestMessages(type, targetId, count);
    },
    getHistoryMessages(conversationType,targetId,objectName,oldestMessageId,count){//获取会话中，从指定消息之前、指定数量的、指定消息类型的最新消息实体
        return RongCloudIMLib.getHistoryMessages(conversationType,targetId,objectName,oldestMessageId,count);
    },
    sendTextMessage(conversationType, targetId, targetName, content) {
        return RongCloudIMLib.sendTextMessage(conversationType, targetId, targetName, content, content);
    },
    sendImageMessage(conversationType, targetId, targetName, imageUrl) {
        return RongCloudIMLib.sendImageMessage(conversationType, targetId, targetName, imageUrl, '');
    },
    sendFileMessage(conversationType, targetId, targetName, fileUrl) {
        return RongCloudIMLib.sendFileMessage(conversationType, targetId, targetName, fileUrl, '');
    },
    voiceBtnPressIn(conversationType, targetId) {
        return RongCloudIMLib.voiceBtnPressIn(conversationType, targetId);
    },
    voiceBtnPressOut(conversationType, targetId) {
        return RongCloudIMLib.voiceBtnPressOut(conversationType, targetId);
    },
    voiceBtnPressCancel(conversationType, targetId) {
        return RongCloudIMLib.voiceBtnPressCancel(conversationType, targetId);
    },
    audioPlayStart(filePath) {
        return RongCloudIMLib.audioPlayStart(filePath);
    },
    audioPlayStop() {
        return RongCloudIMLib.audioPlayStop();
    },
    disconnect(disconnect) {
        return RongCloudIMLib.disconnect(disconnect);
    },
};
