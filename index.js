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

DeviceEventEmitter.addListener('onRongMessageReceived', (resp) => {
    typeof (_onRongCloudMessageReceived) === 'function' && _onRongCloudMessageReceived(resp);
});

const RongCloudIMLibEmitter = new NativeEventEmitter(RongCloudIMLib);

const subscription = RongCloudIMLibEmitter.addListener(
    'onRongMessageReceived',
    (resp) => {
        typeof (_onRongCloudMessageReceived) === 'function' && _onRongCloudMessageReceived(resp);
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
    PUBLIC_SERVICE: 8
};

export default {
    ConversationType: ConversationType,
    onReceived(callback) {
        _onRongCloudMessageReceived = callback;
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
    searchConversations(keyword) {
        return RongCloudIMLib.searchConversations(keyword);
    },
    getConversationList() {
        return RongCloudIMLib.getConversationList();
    },
    getLatestMessages(type, targetId, count) {
        return RongCloudIMLib.getLatestMessages(type, targetId, count);
    },
    sendTextMessage(conversationType, targetId, content) {
        return RongCloudIMLib.sendTextMessage(conversationType, targetId, content, content);
    },
    sendImageMessage(conversationType, targetId, imageUrl) {
        return RongCloudIMLib.sendImageMessage(conversationType, targetId, imageUrl, '');
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
