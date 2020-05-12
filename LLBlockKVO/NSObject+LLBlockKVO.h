//
//  NSObject+LLBlockKVO.h
//  LLBlockKVO
//
//  Created by apple on 2020/5/11.
//  Copyright © 2020 ll. All rights reserved.
//


#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^ll_observerBlock)(id obj, id oldValue, id newValue);

@interface NSObject (LLBlockKVO)

/// 添加观察
/// @param observer 观察者
/// @param key 访问属性
/// @param block 改变回调
- (void)ll_addObserver:(id)observer
                forKey:(NSString *)key
                 block:(ll_observerBlock)block;

/// 移除观察
/// @param observer 观察者
/// @param key 访问属性
- (void)ll_removeObserver:(id)observer
                   forKey:(NSString *)key;
@end

NS_ASSUME_NONNULL_END
