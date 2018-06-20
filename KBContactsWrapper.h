//
//  KBContactsWrapper.h
//  ayh
//
//  Created by administrator on 2018/6/15.
//  Copyright © 2018年 com.msxf. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, selectType){
    
    SelectTypeEmail,
    SelectTypeContact,
    
};
typedef void (^contact)(id contact);
@interface KBContactsWrapper : NSObject 
@property (nonatomic, assign) selectType selectType;
@property (nonatomic, copy) contact  gotContactsBlock;
@property (nonatomic, strong) UIColor *pickerTintColor;

+ (KBContactsWrapper *)shareInstance;

/**
 获取所有联系人
 */
+ (NSArray *)getContactsData;


/**
 获取联系人
 不会请求通讯录权限
 @param contact 联系人
 */
- (void)loadContact:(contact)contact;


/**
 获取联系人
 首次获取会请求通讯录权限
 @param contact 联系人
 */
- (void)loadContactAndPermission:(contact)contact;

/**
 获取通讯录权限

 @param resultBlock 回调 结果
 */
- (void)permissionAndResultBlock:(void (^)(BOOL))resultBlock;

/**
是否有通讯录权限
 */
- (BOOL)isContactsAuthorized;

/**
 ->设置->通讯录权限弹窗
 */
- (void)settingContactPermission;


/**
 ->设置->权限

 @param permissionNeed 权限
 */
- (void)settingPermisson:(NSString *)permissionNeed;

//-(NSDictionary *)launchContactsDict;
//
///**
// 获取通讯录
// */
//- (void )requestContacts :(gotContacts)gotContactsBlock;
//
///**
// 获取通讯录授权状态
// @return PermissionStatus
// */
//- (PermissionStatus)contactPermission;
//
//
///**
// 请求通讯录授权
// @param grantedBlock 授权成功
// @param rejectBlock 授权失败
// */
//- (void)contactsPermission:(granted)grantedBlock reject:(reject)rejectBlock;
//
///**
//  获取通讯录授权状态  (首次请求权限会弹窗)
// @param grantedBlock  授权成功
// @param rejectBlock 授权失败
// @return PermissionStatus
// */
//- (void)contactsPermissionStatus:(granted)grantedBlock reject:(reject)rejectBlock;
//


@end
