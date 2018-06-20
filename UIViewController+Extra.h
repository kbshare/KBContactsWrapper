//
//  ayh
//
//  Created by administrator on 2017/2/15.
//  Copyright © 2017年 com.msxf. All rights reserved.

#import <UIKit/UIKit.h>
@interface UIViewController (Extra)

//判断页面是以何种方式进入的
- (BOOL)isPushed;
//当先显示的
+ (UIViewController *)appVisibleViewController;

//appdelegate window rootViewController
+ (id<UIApplicationDelegate>)appDelegate;
+ (UIWindow *)appWindow;
+ (UIViewController *)appRootViewController;

///navigation
+ (UINavigationController *)appNavigationController;//当前显示的导航控制器
+ (UIViewController *)appNavigationRootViewController;
+ (UIViewController *)appNavigationTopViewController;
+ (UIViewController *)appNavigationVisibleViewController;

///tabBarController
+ (UITabBarController *)appTabBarController;
+ (UIViewController *)appTabBarSelelctedViewController;
+ (UIViewController *)appTabBarTopViewController;
+ (UIViewController *)appTabBarVisibleViewController;


@end
