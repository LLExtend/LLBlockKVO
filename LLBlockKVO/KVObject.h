//
//  KVObject.h
//  LLBlockKVO
//
//  Created by apple on 2020/5/12.
//  Copyright © 2020 apple. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

@interface TextObject : NSObject
@property (nonatomic, copy) NSString *text;
@end

@interface KVObject : NSObject

@property (nonatomic ,assign) NSInteger age;//Tq
@property (nonatomic ,assign) long agelong;//Tq
@property (nonatomic ,assign) short ageshort;//Ts
@property (nonatomic ,assign) long long agelonglong;//Tq
@property (nonatomic ,assign) int ageint;//Ti
@property (nonatomic ,assign) CGFloat age1;//Td
@property (nonatomic ,assign) float agefloat;//Tf
@property (nonatomic ,assign) double ageDouble;//Td
@property (nonatomic ,assign) char ageChar;//Tc
@property (nonatomic ,assign) BOOL ageBOOL;//TB
@property (nonatomic ,assign) Boolean ageBoolean;//TC

@property (nonatomic ,assign) NSUInteger ageU;//TQ
@property (nonatomic ,assign) unsigned long agelongU;//TQ
@property (nonatomic ,assign) unsigned short ageshortU;//TS
@property (nonatomic ,assign) unsigned long long agelonglongU;//TQ
@property (nonatomic ,assign) unsigned int ageintU;//TI
@property (nonatomic ,assign) unsigned char ageCharU;//TC

@property (nonatomic ,copy) NSArray *agearray;//"T@\"NSArray\""
@property (nonatomic ,copy) NSString *name;//"T@\"NSString\""
@property (nonatomic ,strong) TextObject *object;//"T@\"TextObject\""

@end
