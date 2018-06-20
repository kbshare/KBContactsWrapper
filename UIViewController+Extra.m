
//  ayh
//
//  Created by administrator on 2017/2/15.
//  Copyright © 2017年 com.msxf. All rights reserved.
#import "UIViewController+Extra.h"

@implementation UIViewController (Extra)
+ (id<UIApplicationDelegate> )appDelegate{
    return [[UIApplication sharedApplication] delegate];
}

+ (UIWindow *)appWindow{
    return [[self appDelegate] window];
}

+ (UIViewController *)appRootViewController{
    return [[self appWindow] rootViewController];
}

+ (UINavigationController *)appNavigationController{
    __weak UINavigationController *navVc = (UINavigationController *)[self appRootViewController];
    if([navVc isKindOfClass:[UINavigationController class]]){
        return navVc;
    }else if([navVc isKindOfClass:[UITabBarController class]]){
        id nav = [(UITabBarController *)navVc selectedViewController];
        if([nav isKindOfClass:[UINavigationController class]]){
            return nav;
        }
    }
    return nil;
}

+ (UIViewController *)appNavigationRootViewController{
    __weak UINavigationController *navVc = [self appNavigationController];
    if(navVc){
        NSArray *viewControllers = [navVc viewControllers];
        return viewControllers.count?viewControllers[0]:nil;
    }
    return nil;
}

+ (UIViewController *)appNavigationTopViewController{
    __weak UINavigationController *navVc = [self appNavigationController];
    if(navVc){
        return [navVc topViewController];
    }
    return nil;
}

+ (UIViewController *)appNavigationVisibleViewController{
    __weak UINavigationController *navVc = [self appNavigationController];
    if(navVc){
        return [navVc visibleViewController];
    }
    return nil;
}

+ (UITabBarController *)appTabBarController{
    __weak UITabBarController *tabVC = (UITabBarController *)[self appRootViewController];
    if([tabVC isKindOfClass:[UITabBarController class]]){
        return tabVC;
    }
    return nil;
}

+ (UIViewController *)appTabBarSelelctedViewController{
    __weak UITabBarController *tabVc = [self appTabBarController];
    if(tabVc){
        return [tabVc selectedViewController];
    }
    return nil;
}

+ (UIViewController *)appTabBarTopViewController{
    __weak UIViewController *vc = [self appTabBarSelelctedViewController];
    if([vc isKindOfClass:[UINavigationController class]]){
        return [(UINavigationController *)vc topViewController];
    }
    return vc;
}

+ (UIViewController *)appTabBarVisibleViewController{
    __weak UIViewController *vc = [self appTabBarSelelctedViewController];
    if([vc isKindOfClass:[UINavigationController class]]){
        return [(UINavigationController *)vc visibleViewController];
    }
    return vc;
}

- (BOOL)isPushed{
    
    if (!self.navigationController) {
        return NO;
    }
    
    NSArray *viewcontrollers = self.navigationController.viewControllers;
    
    if (viewcontrollers.count>=1) {
        
        if ([viewcontrollers objectAtIndex:viewcontrollers.count-1]==self) {
            return YES;
        }
    }else{
        
        return NO;
    }
    
    return NO;
    
}

//orelsePresent
+ (UIViewController *)appVisibleViewController {
    
    UIViewController *rootViewController = [self appRootViewController];
    return [self getVisibleViewControllerFrom:rootViewController];
}

+ (UIViewController *) getVisibleViewControllerFrom:(UIViewController *) vc {
    if ([vc isKindOfClass:[UINavigationController class]]) {
        return [self getVisibleViewControllerFrom:[((UINavigationController *) vc) visibleViewController]];
    } else if ([vc isKindOfClass:[UITabBarController class]]) {
        return [self getVisibleViewControllerFrom:[((UITabBarController *) vc) selectedViewController]];
    } else {
        if (vc.presentedViewController) {
            return [self getVisibleViewControllerFrom:vc.presentedViewController];
        } else {
            return vc;
        }
    }
}
@end
