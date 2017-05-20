//
//  MessageBusManager.h
//  MQTTMDK
//
//  Created by shengyp on 15/11/16.
//  Copyright © 2015年 shengyp. All rights reserved.
//

#import "MQTTKit.h"

@interface MessageBusManager : NSObject


- (void)connectToHost:(NSString *)host port:(unsigned short)port completionHandler:(void (^)(MQTTConnectionReturnCode code))completionHandler;

- (void)disconnectWithCompletionHandler:(MQTTDisconnectionHandler)completionHandler;

- (void)setDisconnectWithCompletionHandler:(MQTTDisconnectionHandler)completionHandler;

- (void)initWithClientId:(NSString *)clientId;

- (void)initWithClientId:(NSString *)clientId userName:(NSString *)username password:(NSString *)password;


- (void)subscribeTopic:(NSString *)topic completionHandler:(MQTTSubscriptionCompletionHandler)completionHandler;

- (void)subscribeTopic:(NSString *)topic receiveMessageHandler:(MQTTMessageHandler)messageHandler;

- (void)subscribeTopic:(NSString *)topic receiveMessageHandler:(MQTTMessageHandler)messageHandler completionHandler:(MQTTSubscriptionCompletionHandler)completionHandler;

- (void)publishMessage:(NSString *)payload toTopic:(NSString *)topic completionHandler:(void (^)(int mid))completionHandler;

- (void)unsubscribe: (NSString *)topic withCompletionHandler:(void (^)(void))completionHandler;

@end
