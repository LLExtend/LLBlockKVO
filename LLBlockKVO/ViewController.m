//
//  ViewController.m
//  LLBlockKVO
//
//  Created by apple on 2020/5/12.
//  Copyright © 2020 apple. All rights reserved.
//

#import "ViewController.h"
#import "KVObject.h"
#import "NSObject+LLBlockKVO.h"

@interface ViewController ()
@property (nonatomic, strong) KVObject *kvoObject;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
   
    self.kvoObject.age = 21;
    self.kvoObject.name = @"testName";
    self.kvoObject.agefloat = 10.01;
    
    TextObject *object = TextObject.new;
    object.text = @"init Text";
    self.kvoObject.object = object;
    
    
    [self.kvoObject ll_addObserver:self forKey:@"agefloat" block:^(id  _Nonnull obj, id  _Nonnull oldValue, id  _Nonnull newValue) {
        NSLog(@"agefloat --> %@, %@, %@", obj, oldValue, newValue);
    }];
    
    [self.kvoObject ll_addObserver:self forKey:@"name" block:^(id  _Nonnull obj, id  _Nonnull oldValue, id  _Nonnull newValue) {
        NSLog(@"name0 --> %@, %@, %@", obj, oldValue, newValue);
    }];

    [self.kvoObject ll_addObserver:self forKey:@"name" block:^(id  _Nonnull obj, id  _Nonnull oldValue, id  _Nonnull newValue) {
        NSLog(@"name1 --> %@, %@, %@", obj, oldValue, newValue);
    }];
    
    [self.kvoObject ll_addObserver:self forKey:@"age" block:^(id  _Nonnull obj, id  _Nonnull oldValue, id  _Nonnull newValue) {
        NSLog(@"age --> %@, %@, %@", obj, oldValue, newValue);
    }];

    [self.kvoObject ll_addObserver:self forKey:@"object" block:^(id  _Nonnull obj, id  _Nonnull oldValue, id  _Nonnull newValue) {
        NSLog(@"object --> %@, %@, %@", obj, oldValue, newValue);
    }];
    
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    self.kvoObject.age = arc4random()%50+10;
    self.kvoObject.name = [self randomString];
    self.kvoObject.object.text = @"modift text";
    self.kvoObject.object = TextObject.new;
    
    self.kvoObject.agefloat = 12.09;
}

- (NSString *)randomString {
  
    //1.时间戳
    NSTimeInterval time = [[NSDate date] timeIntervalSince1970];
    NSString *timeString = [NSString stringWithFormat:@"%.0f",time];
    
    //2.随机字符串
    NSString *kRandomAlphabet = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    NSInteger length = 10;
    NSMutableString *randomString = [NSMutableString stringWithCapacity:length];
    for (int i = 0; i < length; i++) {
        [randomString appendFormat:@"%C", [kRandomAlphabet characterAtIndex:arc4random_uniform((u_int32_t)[kRandomAlphabet length])]];
    }

    NSMutableArray *array = [[NSMutableArray alloc] init];
    [array addObject:randomString];
    [array addObject:timeString];
    return [array componentsJoinedByString:@"-"];
}

- (void)dealloc {
    [self.kvoObject ll_removeObserver:self forKey:@"name"];
    [self.kvoObject ll_removeObserver:self forKey:@"age"];
    [self.kvoObject ll_removeObserver:self forKey:@"object"];
}

- (KVObject *)kvoObject {
    if (!_kvoObject) {
        _kvoObject = KVObject.new;
    }
    return _kvoObject;
}
@end
