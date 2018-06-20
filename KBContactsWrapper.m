//
//  KBContactsWrapper.m
//  ayh
//
//  Created by administrator on 2018/6/15.
//  Copyright © 2018年 com.msxf. All rights reserved.
//

#import "KBContactsWrapper.h"
#import "UIViewController+Extra.h"
#import <Contacts/Contacts.h>
#import <ContactsUI/ContactsUI.h>
#import <AddressBook/AddressBook.h>
#import <AddressBookUI/AddressBookUI.h>

@interface KBContactsWrapper ()<CNContactPickerDelegate,ABPeoplePickerNavigationControllerDelegate>

@end

@implementation KBContactsWrapper

+ (KBContactsWrapper *)shareInstance{
    static KBContactsWrapper *shareInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shareInstance = [[KBContactsWrapper alloc] init];
    });
    shareInstance.selectType = SelectTypeContact;
    return shareInstance;
}
- (void)setSelectType:(selectType)selectType{
    _selectType = selectType;
}
-(void)loadContact:(contact)contact{
    _gotContactsBlock = contact;
    [self launchContact];
}

- (void)launchContact{
    UIViewController *picker;
    if([CNContactPickerViewController class]) {
        picker = [[CNContactPickerViewController alloc] init];
        ((CNContactPickerViewController *)picker).delegate = self;
    } else {
        picker = [[ABPeoplePickerNavigationController alloc] init];
        [((ABPeoplePickerNavigationController *)picker) setPeoplePickerDelegate:self];
    }
    
    UIViewController *root = [[[UIApplication sharedApplication] delegate] window].rootViewController;
    BOOL modalPresent = (BOOL) (root.presentedViewController);
    if (modalPresent) {
        UIViewController *parent = root.presentedViewController;
        [UINavigationBar appearance].tintColor = _pickerTintColor ?: [UIColor whiteColor];
        [parent presentViewController:picker animated:YES completion:nil];
    } else {
        [UINavigationBar appearance].tintColor = _pickerTintColor ?: [UIColor whiteColor];
        [root presentViewController:picker animated:YES completion:nil];
    }
}

-(void)loadContactAndPermission:(contact)contact{
    _gotContactsBlock = contact;
    if (@available(iOS 9.0, *)) {
        CNAuthorizationStatus status = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
        if (status == CNAuthorizationStatusNotDetermined) {
            CNContactStore *store = [[CNContactStore alloc] init];
            [store requestAccessForEntityType:CNEntityTypeContacts
                            completionHandler:^(BOOL granted, NSError* _Nullable error) {
                                if (error) {
                                }else {
                                    [self launchContact];
                                } }];
        } else if(status == CNAuthorizationStatusRestricted || status == CNAuthorizationStatusDenied) {
            [self settingContactPermission];
        } else if (status == CNAuthorizationStatusAuthorized){
            [self launchContact];
        }
    }else{
        ABAddressBookRef bookref = ABAddressBookCreateWithOptions(NULL, NULL);
        ABAuthorizationStatus status = ABAddressBookGetAuthorizationStatus();
        if (status == kABAuthorizationStatusNotDetermined){
            ABAddressBookRequestAccessWithCompletion(bookref, ^(bool granted, CFErrorRef error) {
                if (error) {
                } if (granted) {
                    [self launchContact];
                }
            });
            
        }else  if(status == kABAuthorizationStatusAuthorized){
            [self launchContact];
        }else {
            [self settingContactPermission];
        }
    }
}

- (void)permissionAndResultBlock:(void (^)(BOOL))resultBlock{
    
    if (@available(iOS 9.0, *)) {
        CNAuthorizationStatus status = [CNContactStore authorizationStatusForEntityType:CNEntityTypeContacts];
        if (status == CNAuthorizationStatusNotDetermined) {
            CNContactStore *store = [[CNContactStore alloc] init];
            [store requestAccessForEntityType:CNEntityTypeContacts
                            completionHandler:^(BOOL granted, NSError* _Nullable error) {
                                if (error) {
                                    resultBlock(NO);
                                }else {
                                    resultBlock(YES);
                                } }];
            
        } else if (status == CNAuthorizationStatusAuthorized){
            resultBlock(YES);
        }else{// CNAuthorizationStatusRestricted CNAuthorizationStatusDenied)
            resultBlock(NO);
        }
    }else{
        ABAddressBookRef bookref = ABAddressBookCreateWithOptions(NULL, NULL);
        ABAuthorizationStatus status = ABAddressBookGetAuthorizationStatus();
        if (status == kABAuthorizationStatusNotDetermined){
            ABAddressBookRequestAccessWithCompletion(bookref, ^(bool granted, CFErrorRef error) {
                if (error) {
                    resultBlock(NO);
                    
                } if (granted) {
                    resultBlock(YES);
                }
            });
            
        }else  if(status == kABAuthorizationStatusAuthorized){
            resultBlock(YES);
        }else {
            resultBlock(NO);
        }
    }
}

#pragma mark - Event handlers - iOS 9+
- (void)contactPicker:(CNContactPickerViewController *)picker didSelectContact:(CNContact *)contact {
    switch(_selectType){
        case SelectTypeContact:
        {
            NSMutableDictionary *contactData = [self emptyContactDict];
            
            NSString *fullName = [self getFullNameForFirst:contact.givenName middle:contact.middleName last:contact.familyName ];
            NSArray *phoneNos = contact.phoneNumbers;
            NSArray *emailAddresses = contact.emailAddresses;
            
            [contactData setValue:fullName forKey:@"name"];
            
            //Return first phone number
            if([phoneNos count] > 0) {
                CNPhoneNumber *phone = ((CNLabeledValue *)phoneNos[0]).value;
                [contactData setValue:phone.stringValue forKey:@"phone"];
            }
            
            //Return first email address
            if([emailAddresses count] > 0) {
                [contactData setValue:((CNLabeledValue *)emailAddresses[0]).value forKey:@"email"];
            }
            
            [self contactPicked:contactData];
        }
            break;
        case SelectTypeEmail :
        {
            /* Return Only email address as string */
            if([contact.emailAddresses count] < 1) {
                [self pickerNoEmail];
                return;
            }
            
            NSString *email = contact.emailAddresses[0].value;
            [self emailPicked:email];
        }
            break;
        default:
            //Should never happen, but just in case, reject promise
            //            [self pickerError];
            break;
    }
}

- (void)contactPickerDidCancel:(CNContactPickerViewController *)picker {
    [self pickerCancelled];
}
#pragma mark - Event handlers - iOS 8

/* Same functionality as above, implemented using iOS8 AddressBook library */
- (void)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker didSelectPerson:(ABRecordRef)person {
    switch(_selectType) {
        case(SelectTypeContact):
        {
            
            /* Return NSDictionary ans JS Object to RN, containing basic contact data
             This is a starting point, in future more fields should be added, as required.
             This could also be extended to return arrays of phone numbers, email addresses etc. instead of jsut first found
             */
            NSMutableDictionary *contactData = [self emptyContactDict];
            NSString *fNameObject, *mNameObject, *lNameObject;
            fNameObject = (__bridge NSString *) ABRecordCopyValue(person, kABPersonFirstNameProperty);
            mNameObject = (__bridge NSString *) ABRecordCopyValue(person, kABPersonMiddleNameProperty);
            lNameObject = (__bridge NSString *) ABRecordCopyValue(person, kABPersonLastNameProperty);
            
            NSString *fullName = [self getFullNameForFirst:fNameObject middle:mNameObject last:lNameObject];
            
            //Return full name
            [contactData setValue:fullName forKey:@"name"];
            
            //Return first phone number
            ABMultiValueRef phoneMultiValue = ABRecordCopyValue(person, kABPersonPhoneProperty);
            NSArray *phoneNos = (__bridge NSArray *)ABMultiValueCopyArrayOfAllValues(phoneMultiValue);
            if([phoneNos count] > 0) {
                [contactData setValue:phoneNos[0] forKey:@"phone"];
            }
            
            //Return first email
            ABMultiValueRef emailMultiValue = ABRecordCopyValue(person, kABPersonEmailProperty);
            NSArray *emailAddresses = (__bridge NSArray *)ABMultiValueCopyArrayOfAllValues(emailMultiValue);
            if([emailAddresses count] > 0) {
                [contactData setValue:emailAddresses[0] forKey:@"email"];
            }
            [self contactPicked:contactData];
        }
            break;
        case(SelectTypeEmail):
        {
            /* Return Only email address as string */
            ABMultiValueRef emailMultiValue = ABRecordCopyValue(person, kABPersonEmailProperty);
            NSArray *emailAddresses = (__bridge NSArray *)ABMultiValueCopyArrayOfAllValues(emailMultiValue);
            if([emailAddresses count] < 1) {
                [self pickerNoEmail];
                return;
            }
            
            [self emailPicked:emailAddresses[0]];
        }
            break;
            
        default:
            return;
    }
    
}

- (void)pickerCancelled {
    
}

- (NSMutableDictionary *) emptyContactDict {
    return [[NSMutableDictionary alloc] initWithObjects:@[@"", @"", @""] forKeys:@[@"name", @"phone", @"email"]];
}



- (void)pickerNoEmail {
    if (_gotContactsBlock) {
        _gotContactsBlock(@"Email Error: NO Email...");
    }
}

-(void)emailPicked:(NSString *)email {
    
    if (_gotContactsBlock) {
        _gotContactsBlock(email);
    }
}


-(void)contactPicked:(NSDictionary *)contactData {
    if (_gotContactsBlock) {
        _gotContactsBlock(contactData);
    }
}

- (void)settingPermisson:(NSString *)permissionNeed{
    
    NSString *tip = [NSString stringWithFormat:@"您的%@没授权哦~\n去\"设置>隐私>%@\"开启一下吧",permissionNeed,permissionNeed];
    
    UIAlertView * alert = [[UIAlertView alloc]initWithTitle:@"提示" message:tip delegate:self cancelButtonTitle:@"暂不授权" otherButtonTitles:@"确定", nil];
    [alert show];
    
    
//    [AYHTools creatAlertView:@"提示" message:tip cancel:@"暂不授权" sure:@"确定" handler:^(NSString *type) {
//
//        if ([type isEqualToString:@"确定"]){
//
//            NSURL*url =[NSURL URLWithString:UIApplicationOpenSettingsURLString];
//
//            if([[UIApplication sharedApplication] canOpenURL:url]) {
//
//                NSURL*url =[NSURL URLWithString:UIApplicationOpenSettingsURLString];
//
//                [[UIApplication sharedApplication] openURL:url];
//            }
//        }
//
//    } delegate:[UIViewController appVisibleViewController] otherButtonTitles:nil, nil];
}
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 1){
        
        NSURL*url =[NSURL URLWithString:UIApplicationOpenSettingsURLString];
        
        if([[UIApplication sharedApplication] canOpenURL:url]) {
            
            NSURL*url =[NSURL URLWithString:UIApplicationOpenSettingsURLString];
            
            [[UIApplication sharedApplication] openURL:url];
        }
    }
}
- (void)settingContactPermission{
    
    [self settingPermisson:@"通讯录"];
}

/**
 Return full name as single string from first last and middle name strings, which may be empty
 */
-(NSString *) getFullNameForFirst:(NSString *)fName middle:(NSString *)mName last:(NSString *)lName {
    //Check whether to include middle name or not
    NSArray *names = (mName.length > 0) ? [NSArray arrayWithObjects:lName, mName, fName, nil] : [NSArray arrayWithObjects:lName, fName, nil];;
    return [names componentsJoinedByString:@" "];
}


@end
