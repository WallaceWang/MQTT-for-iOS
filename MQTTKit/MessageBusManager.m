//
//  MessageBusManager.m
//  MQTTMDK
//
//  Created by shengyp on 15/11/16.
//  Copyright © 2015年 shengyp. All rights reserved.
//

#import "MessageBusManager.h"

static MessageBusManager* _instance = nil;

dispatch_queue_t messageBusQueue;

@interface MessageBusManager ()

// create a property for the MQTTClient that is used to send and receive the message
@property (nonatomic, strong) MQTTClient *client;

// create a property for subscribe that is used to receive the message
@property (nonatomic, strong) NSMutableDictionary *subscribeMessageDictionary;

@property (nonatomic, copy) MQTTDisconnectionHandler disconnectionHandler;

@end

@implementation MessageBusManager

- (instancetype)init
{
    self = [super init];
    if (self) {
        const char* cstrClientId = [@"MessageBusManager" cStringUsingEncoding:NSUTF8StringEncoding];
        messageBusQueue = dispatch_queue_create(cstrClientId, NULL);
        self.subscribeMessageDictionary = [[NSMutableDictionary alloc] initWithCapacity:0];
    }
    return self;
}

- (void)connectToHost:(NSString *)host port:(unsigned short)port completionHandler:(void (^)(MQTTConnectionReturnCode code))completionHandler
{
    __block NSMutableDictionary *dictionary = self.subscribeMessageDictionary;
    
    dispatch_async(messageBusQueue, ^{
        if(host.length > 0 && port > 0){
            self.client.host = host;
            self.client.port = port;
            [self.client connectWithCompletionHandler:^(MQTTConnectionReturnCode code) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if(completionHandler){
                        completionHandler(code);
                    }
                });
                
                [self.client setMessageHandler:^(MQTTMessage *message){
                    if(nil != message){
                        MQTTMessageHandler messageHandler = [dictionary objectForKey:message.topic];
                        if(messageHandler){
                            dispatch_async(dispatch_get_main_queue(), ^{
                                messageHandler(message);
                            });
                        }
                    }
                }];
            }];
        }
    });
}

- (void)disconnectWithCompletionHandler:(MQTTDisconnectionHandler)completionHandler
{
    self.disconnectionHandler = completionHandler;
    
    __block NSMutableDictionary *dictionary = self.subscribeMessageDictionary;
    
    dispatch_async(messageBusQueue, ^{
        
        [self.client disconnectWithCompletionHandler:^(NSUInteger code) {
            [dictionary removeAllObjects];
            if(self.disconnectionHandler){
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.disconnectionHandler(code);
                });
            }
        }];
    });
}

- (void)setDisconnectWithCompletionHandler:(MQTTDisconnectionHandler)completionHandler
{
    if(completionHandler){
        self.disconnectionHandler = completionHandler;
        self.client.disconnectionHandler = completionHandler;
    }
}

- (void)initWithClientId:(NSString *)clientId
{
    if(nil == self.client && clientId.length > 0){
        self.client = [[MQTTClient alloc] initWithClientId:clientId];
    }
}

-(void)initWithClientId:(NSString *)clientId userName:(NSString *)username password:(NSString *)password{
    
    if(nil == self.client && clientId.length > 0){
        self.client = [[MQTTClient alloc] initWithClientId:clientId userName:username password:password];
    }
    
    
}

- (void)subscribeTopic:(NSString *)topic completionHandler:(MQTTSubscriptionCompletionHandler)completionHandler
{
    if(nil != topic && topic.length > 0){
        dispatch_async(messageBusQueue, ^ {
            [self.client subscribe:topic withQos:AtMostOnce completionHandler:^(NSArray *grantedQos) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if(completionHandler){
                        completionHandler(grantedQos);
                    }
                });
            }];
        });
    }
}

- (void)subscribeTopic:(NSString *)topic receiveMessageHandler:(MQTTMessageHandler)messageHandler
{
    if(nil != topic && topic.length > 0 && messageHandler){
        [self.subscribeMessageDictionary setObject:[messageHandler copy] forKey:topic];
    }
}

- (void)subscribeTopic:(NSString *)topic receiveMessageHandler:(MQTTMessageHandler)messageHandler completionHandler:(MQTTSubscriptionCompletionHandler)completionHandler
{
    if(nil != topic && topic.length > 0){
        
        [self subscribeTopic:topic receiveMessageHandler:messageHandler];
        
        dispatch_async(messageBusQueue, ^ {
            [self.client subscribe:topic withQos:AtMostOnce completionHandler:^(NSArray *grantedQos) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if(completionHandler){
                        completionHandler(grantedQos);
                    }
                });
            }];
        });
    }
}


-(void)unsubscribe:(NSString *)topic withCompletionHandler:(void (^)(void))completionHandler{
    
    [self.client unsubscribe:topic withCompletionHandler:completionHandler];
}

- (void)publishMessage:(NSString *)payload toTopic:(NSString *)topic completionHandler:(void (^)(int mid))completionHandler
{
    if(nil != payload && payload.length > 0 && nil !=topic && topic.length > 0){
        [self.client publishString:payload toTopic:topic withQos:ExactlyOnce retain:NO completionHandler:completionHandler];
    }
}

@end
