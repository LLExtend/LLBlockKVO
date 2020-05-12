//
//  NSObject+LLBlockKVO.m
//  LLBlockKVO
//
//  Created by apple on 2020/5/11.
//  Copyright © 2020 ll. All rights reserved.
//

#import "NSObject+LLBlockKVO.h"
#import <objc/runtime.h>
#import <objc/message.h>


typedef NS_ENUM(NSInteger, LLEncodeType) {
    LLEncodeType_int = 0, // NSInteger(int long short long long)
    LLEncodeType_float  , // CGFloat(float double)
    LLEncodeType_bool   , // BOOL
    LLEncodeType_char   , // char
    LLEncodeType_uint   , // NSUInteger
    LLEncodeType_uchar  , // unsigned char
    LLEncodeType_id     , // OC id
};

NSString * const kLLGenerateAssistSuffixKey = @"LLGenerateAssistSuffixKey_";
NSString * const kLLBlockKVOClassSuffix = @"_NotifyBlockKVO";
NSString * const kLLBlcokKVOAssociatedObservers = @"LLBlcokKVOAssociatedObservers";

#pragma mark - LLObserverInfoItem 类
@interface LLObserverInfoItem : NSObject
@property (nonatomic, weak) NSObject *observer;
@property (nonatomic, copy) NSString *key;
@property (nonatomic, copy) ll_observerBlock block;
@end

@implementation LLObserverInfoItem

- (instancetype)initWithObserver:(id)observer key:(NSString *)key block:(ll_observerBlock)block {
    if (self = [super init]) {
        _observer = observer;
        _key = key;
        _block = block;
    }
    return self;
}
@end



static NSString *ll_generateGetterForSetter(NSString *setter) {
    if (setter.length <= 0 ||
        ![setter hasPrefix:@"set"] ||
        ![setter hasSuffix:@":"]) {
        return nil;
    }
    
    NSString *key = [setter substringWithRange:NSMakeRange(3, setter.length - 4)];
    
    NSString *firstLetter = [[key substringToIndex:1] lowercaseString];
    key = [key stringByReplacingCharactersInRange:NSMakeRange(0, 1)
                                       withString:firstLetter];
    return key;
}

static LLEncodeType ll_dynamicEncodeTypeHandle(objc_property_t property) {
    NSString *propertyAttributes = [NSString stringWithUTF8String:property_getAttributes(property)];
    NSArray *encodingTypeKeys = [propertyAttributes componentsSeparatedByString:@","];
    NSLog(@"encodingTypeKeys === %@",encodingTypeKeys);
    
    NSString *encodingTypeKey = encodingTypeKeys.firstObject;
    
    /*
     整形
     NSInteger
     int
     long
     short
     long long
     */
    NSArray *integerArray = @[@"Tq",@"Ts",@"Ti"];
    if ([integerArray containsObject:encodingTypeKey]) {
        return LLEncodeType_int;
    }
    
    /*
     无符号整形
     NSUInteger
     unsigned int
     unsigned long
     unsigned short
     unsigned long long
     */
    NSArray *uintegerArray = @[@"TQ",@"TS",@"TI"];
    if ([uintegerArray containsObject:encodingTypeKey]) {
        return LLEncodeType_uint;
    }
    
    // CGFloat double float
    NSArray *floatArray = @[@"Td",@"Tf"];
    if ([floatArray containsObject:encodingTypeKey]) {
        return LLEncodeType_float;
    }
    
    // BOOL boolean
    NSArray *boolArray = @[@"TB",@"TC"];
    if ([boolArray containsObject:encodingTypeKey]) {
        return LLEncodeType_bool;
    }
    
    // char
    NSArray *charArray = @[@"Tc"];
    if ([charArray containsObject:encodingTypeKey]) {
        return LLEncodeType_char;
    }
    
    // unsigned char
    NSArray *ucharArray = @[@"TC"];
    if ([ucharArray containsObject:encodingTypeKey]) {
        return LLEncodeType_uchar;
    }
    
    // OC id类型
    return LLEncodeType_id;
    
    // API地址 https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtPropertyIntrospection.html#//apple_ref/doc/uid/TP40008048-CH101-SW1
}

static void ll_dynamicExecBlock(id obj, id oldValue, id newValue, id getterName) {
    NSMutableDictionary *observers = objc_getAssociatedObject(obj, (__bridge const void *)(kLLBlcokKVOAssociatedObservers));

    NSString *appointPathName = [NSString stringWithFormat:@"%@%@",kLLGenerateAssistSuffixKey,getterName];

    for (NSString *each in observers.allKeys) {
        LLObserverInfoItem *item = observers[each];
        if ([each hasSuffix:appointPathName]) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                item.block(obj, oldValue, newValue);
            });
        }
    }
}

static struct objc_super ll_dynaminMsgSendSuper(id obj) {
    struct objc_super superclazz = {
        .receiver = obj,
        .super_class = class_getSuperclass(object_getClass(obj))
    };
    
    return superclazz;
}

static void ll_dynaminKVOSetterFloat(id self, SEL _cmd, float value) {
    NSString *setterName = NSStringFromSelector(_cmd);
    NSString *getterName = ll_generateGetterForSetter(setterName);
    
    id oldValue = [self valueForKey:getterName];
    id newValue = [NSNumber numberWithFloat:value];;
    
    struct objc_super superclazz = ll_dynaminMsgSendSuper(self);
    
    void (*objc_msgSendSuperCasted)(void *, SEL, float) = (void *)objc_msgSendSuper;
    objc_msgSendSuperCasted(&superclazz, _cmd, (float)value);

    ll_dynamicExecBlock(self, oldValue, newValue, getterName);
}

static void ll_dynaminKVOSetterInteger(id self, SEL _cmd, NSInteger value) {
    NSString *setterName = NSStringFromSelector(_cmd);
    NSString *getterName = ll_generateGetterForSetter(setterName);
    
    id newValue = [NSNumber numberWithInteger:(NSInteger)value];;
    id oldValue = [self valueForKey:getterName];
    
    struct objc_super superclazz = ll_dynaminMsgSendSuper(self);
    
    void (*objc_msgSendSuperCasted)(void *, SEL, NSInteger) = (void *)objc_msgSendSuper;
    objc_msgSendSuperCasted(&superclazz, _cmd, (NSInteger)value);

    ll_dynamicExecBlock(self, oldValue, newValue, getterName);
}

static void ll_dynaminKVOSetterUInteger(id self, SEL _cmd, NSUInteger value) {
    NSString *setterName = NSStringFromSelector(_cmd);
    NSString *getterName = ll_generateGetterForSetter(setterName);
    
    id newValue = [NSNumber numberWithUnsignedInteger:(NSUInteger)value];;
    id oldValue = [self valueForKey:getterName];
    
    struct objc_super superclazz = ll_dynaminMsgSendSuper(self);
    
    void (*objc_msgSendSuperCasted)(void *, SEL, NSUInteger) = (void *)objc_msgSendSuper;
    objc_msgSendSuperCasted(&superclazz, _cmd, (NSUInteger)value);

    ll_dynamicExecBlock(self, oldValue, newValue, getterName);
}

static void ll_dynaminKVOSetterBool(id self, SEL _cmd, BOOL value) {
    NSString *setterName = NSStringFromSelector(_cmd);
    NSString *getterName = ll_generateGetterForSetter(setterName);
    
    id newValue = [NSNumber numberWithBool:(BOOL)value];;
    id oldValue = [self valueForKey:getterName];
    
    struct objc_super superclazz = ll_dynaminMsgSendSuper(self);
    
    void (*objc_msgSendSuperCasted)(void *, SEL, BOOL) = (void *)objc_msgSendSuper;
    objc_msgSendSuperCasted(&superclazz, _cmd, (BOOL)value);

    ll_dynamicExecBlock(self, oldValue, newValue, getterName);
}

static void ll_dynaminKVOSetterChar(id self, SEL _cmd, char value) {
    NSString *setterName = NSStringFromSelector(_cmd);
    NSString *getterName = ll_generateGetterForSetter(setterName);
    
    id newValue = [NSNumber numberWithChar:(char)value];;
    id oldValue = [self valueForKey:getterName];
    
    struct objc_super superclazz = ll_dynaminMsgSendSuper(self);
    
    void (*objc_msgSendSuperCasted)(void *, SEL, char) = (void *)objc_msgSendSuper;
    objc_msgSendSuperCasted(&superclazz, _cmd, (char)value);

    ll_dynamicExecBlock(self, oldValue, newValue, getterName);
}

static void ll_dynaminKVOSetterUChar(id self, SEL _cmd, unsigned char value) {
    NSString *setterName = NSStringFromSelector(_cmd);
    NSString *getterName = ll_generateGetterForSetter(setterName);
    
    id newValue = [NSNumber numberWithUnsignedChar:(unsigned char)value];;
    id oldValue = [self valueForKey:getterName];
    
    struct objc_super superclazz = ll_dynaminMsgSendSuper(self);
    
    void (*objc_msgSendSuperCasted)(void *, SEL, unsigned char) = (void *)objc_msgSendSuper;
    objc_msgSendSuperCasted(&superclazz, _cmd, (unsigned char)value);

    ll_dynamicExecBlock(self, oldValue, newValue, getterName);
}

static void ll_dynaminKVOSetterId(id self, SEL _cmd, id value) {
    NSString *setterName = NSStringFromSelector(_cmd);
    NSString *getterName = ll_generateGetterForSetter(setterName);
    
    id newValue = value;
    id oldValue = [self valueForKey:getterName];
    
    struct objc_super superclazz = ll_dynaminMsgSendSuper(self);
    
    void (*objc_msgSendSuperCasted)(void *, SEL, id) = (void *)objc_msgSendSuper;
    objc_msgSendSuperCasted(&superclazz, _cmd, (id)value);

    ll_dynamicExecBlock(self, oldValue, newValue, getterName);
}

@implementation NSObject (LLBlockKVO)
#pragma mark - public method
- (void)ll_addObserver:(id)observer
                forKey:(NSString *)key
                 block:(nonnull ll_observerBlock)block {
    // 获取setter sel
    SEL setterSel = NSSelectorFromString([self generateSetterForKey:key]);
    //
    Method setterMethod = class_getInstanceMethod(self.class, setterSel);
    if (!setterMethod) {
        NSString *reason = [NSString stringWithFormat:@"%@对象 不能根据key：%@生成有效setter", self, key];
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:reason
                                     userInfo:nil];
        return ;
    }
    
    Class oriClass = object_getClass(self);
    NSString *oriClassName = NSStringFromClass(oriClass);
    
    if (![oriClassName hasSuffix:kLLBlockKVOClassSuffix]) {
        // 生成KVO类
        oriClass = [self dynamicGenerateKVOClassWithOriClassName:oriClassName];
        // 更换isa指向
        object_setClass(self, oriClass);
    }
    
    // 属性列表
    unsigned int count = 0;
    objc_property_t *properties = class_copyPropertyList(class_getSuperclass(object_getClass(self)), &count);
    
    LLEncodeType encodeType = LLEncodeType_id;
    for (int i = 0; i < count; i++) {
        objc_property_t property = properties[i];
        const char *name = property_getName(property);
        NSString *propertyName = [NSString stringWithUTF8String:name];
        if ([propertyName isEqualToString:key]) {
            encodeType = ll_dynamicEncodeTypeHandle(property);
            break;
        }
    }
    
    if (class_getMethodImplementation(oriClass, setterSel) == NULL) {
        
        class_addMethod(oriClass, setterSel, [self getMethodImplementationWithEncodeType:encodeType], method_getTypeEncoding(setterMethod));
    } else {
        class_replaceMethod(oriClass, setterSel, [self getMethodImplementationWithEncodeType:encodeType], method_getTypeEncoding(setterMethod));
    }

    LLObserverInfoItem *item = [[LLObserverInfoItem alloc] initWithObserver:observer key:key block:block];
    NSMutableDictionary *observers = objc_getAssociatedObject(self, (__bridge const void *)(kLLBlcokKVOAssociatedObservers));
    if (!observers) {
        observers = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, (__bridge const void *)(kLLBlcokKVOAssociatedObservers), observers, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    observers[[self generateKeyWithObserver:observer key:key]] = item;
}

- (void)ll_removeObserver:(id)observer forKey:(NSString *)key {
    NSMutableDictionary* observers = objc_getAssociatedObject(self, (__bridge const void *)(kLLBlcokKVOAssociatedObservers));
    [observers removeObjectForKey:[self generateKeyWithObserver:observer key:key]];
}


#pragma mark - private method

/// 根据属性对应的数据类型 获取不同IMP
/// @param encodeType 对应枚举类型
- (IMP)getMethodImplementationWithEncodeType:(LLEncodeType)encodeType {
    IMP imp;
    switch (encodeType) {
        case LLEncodeType_id:
            imp = (IMP)ll_dynaminKVOSetterId;
            break;
        
        case LLEncodeType_int:
            imp = (IMP)ll_dynaminKVOSetterInteger;
            break;
    
        case LLEncodeType_uint:
            imp = (IMP)ll_dynaminKVOSetterUInteger;
            break;
        
        case LLEncodeType_bool:
            imp = (IMP)ll_dynaminKVOSetterBool;
            break;
        
        case LLEncodeType_char:
            imp = (IMP)ll_dynaminKVOSetterChar;
            break;
        
        case LLEncodeType_uchar:
            imp = (IMP)ll_dynaminKVOSetterUChar;
            break;
        
        case LLEncodeType_float:
            imp = (IMP)ll_dynaminKVOSetterFloat;
            break;
    }
    return imp;
}

/// 由访问属性 生成 对应 setter
/// @param key 访问属性
- (NSString *)generateSetterForKey:(NSString *)key {
    if (key.length <= 0) return nil;
    
    NSString *firstLetter = [[key substringToIndex:1] uppercaseString];
    NSString *remainingLetters = [key substringFromIndex:1];
    
    NSString *setter = [NSString stringWithFormat:@"set%@%@:", firstLetter, remainingLetters];
    
    return setter;
}

/// 由setter 生成对应 getter
/// @param setter setter
- (NSString *)generateGetterForSetter:(NSString *)setter {
    return ll_generateGetterForSetter(setter);
}

/// 动态生成kvo监听类
/// @param oriClassName 原类类名
- (Class)dynamicGenerateKVOClassWithOriClassName:(NSString *)oriClassName {
    NSString *dynamicKVOClassName = [NSString stringWithFormat:@"%@%@",oriClassName,kLLBlockKVOClassSuffix];
    Class dynamicKVOClass = NSClassFromString(dynamicKVOClassName);
    
    // 如果已存在 直接返回
    if (dynamicKVOClass) {
        return dynamicKVOClass;
    }
    
    // 不存在 动态创建
    Class oriClass = object_getClass(self);
    Class dynClass = objc_allocateClassPair(oriClass, dynamicKVOClassName.UTF8String, 0);
    
    objc_registerClassPair(dynClass);
    
    return dynClass;
}

/// 生成key
/// @param observer 观察者对象
/// @param key 访问属性名
- (NSString *)generateKeyWithObserver:(id)observer key:(NSString *)key {
    // 生成规则 observer内存地址 + self 内存地址 + kLLGenerateAssistSuffixKey + key
    return [NSString stringWithFormat:@"%p%p%@%@",observer,self,kLLGenerateAssistSuffixKey,key];
}

@end
