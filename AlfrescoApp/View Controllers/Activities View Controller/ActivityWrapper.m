//
//  ActivityHelper.m
//  AlfrescoApp
//
//  Created by Mike Hatfield on 25/04/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import "ActivityWrapper.h"
#import "Utility.h"
#import "UIColor+Custom.h"

static NSString * const kActivitySummaryTitle = @"title";
static NSString * const kActivitySummaryFirstName = @"firstName";
static NSString * const kActivitySummaryLastName = @"lastName";
static NSString * const kActivitySummaryUserFirstName = @"userFirstName";
static NSString * const kActivitySummaryUserLastName = @"userLastName";
static NSString * const kActivitySummaryGroupName = @"groupName";
static NSString * const kActivitySummaryMemberUserName = @"memberUserName";
static NSString * const kActivitySummaryMemberPersonId = @"memberPersonId";
static NSString * const kActivitySummaryMemberFirstName = @"memberFirstName";
static NSString * const kActivitySummaryMemberLastName = @"memberLastName";
static NSString * const kActivitySummaryFollowerFirstName = @"followerFirstName";
static NSString * const kActivitySummaryFollowerLastName = @"followerLastName";
static NSString * const kActivitySummarySubscriberFirstName = @"subscriberFirstName";
static NSString * const kActivitySummarySubscriberLastName = @"subscriberLastName";
static NSString * const kActivitySummaryRole = @"role";
static NSString * const kActivitySummaryStatus = @"status";
static NSString * const kActivitySummaryPage = @"page";
static NSString * const kActivitySummaryNode = @"node";
static NSString * const kActivitySummaryCustom0 = @"custom0";
static NSString * const kActivitySummaryCustom1 = @"custom1";

@interface ActivityWrapper ()

@property (nonatomic, strong) AlfrescoActivityEntry *activityEntry;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *fullName;
@property (nonatomic, strong) NSString *secondFullName;
@property (nonatomic, strong) NSString *siteTitle;
@property (nonatomic, strong) NSString *custom0;
@property (nonatomic, strong) NSString *custom1;
@property (nonatomic, assign) BOOL suppressSite;

@property (nonatomic, strong, readwrite) NSString *avatarUserName;
@property (nonatomic, strong, readwrite) NSAttributedString *attributedDetailString;
@property (nonatomic, strong, readwrite) NSString *detailString;
@property (nonatomic, strong, readwrite) NSString *dateString;

@end

@implementation ActivityWrapper

+ (NSArray *)suppressedSiteTypes
{
    static NSArray *_types;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _types = @[@"org.alfresco.site.group-added",
                   @"org.alfresco.site.group-removed",
                   @"org.alfresco.site.user-joined",
                   @"org.alfresco.site.user-left",
                   @"org.alfresco.site.liked",
                   @"org.alfresco.subscriptions.followed",
                   @"org.alfresco.subscriptions.subscribed",
                   @"org.alfresco.profile.status-changed"];
    });
    return _types;
}

- (id)initWithActivityEntry:(AlfrescoActivityEntry *)activityEntry
{
    self = [super init];
    if (self)
    {
        self.activityEntry = activityEntry;
        [self parseActivityEntry];
        [self renderActivityLabels];
    }
    return self;
}

- (NSString *)nodeIdentifier
{
    return self.activityEntry.nodeIdentifier;
}

- (NSString *)nodeName
{
    return self.title;
}

- (BOOL)isDocument
{
    return self.activityEntry.isDocument;
}

- (BOOL)isFolder
{
    return self.activityEntry.isFolder;
}

- (BOOL)isDeleteActivity
{
    return self.activityEntry.isDeleted;
}

- (NSString *)description
{
    if (self.activityEntry)
    {
        return [NSString stringWithFormat:@"%@ %@", super.description, self.detailString];
    }
    return [super description];
}

#pragma mark - Private implementation

- (NSString *)title
{
    return _title ? _title : NSLocalizedStringFromTable(@"activity.unknown-item", @"Activities", "Unknown Item");
}

- (NSString *)fullName
{
    return _fullName ? _fullName : NSLocalizedStringFromTable(@"activity.unknown-user", @"Activities", @"Unknown User");
}

- (NSString *)siteTitle
{
    return _siteTitle ? _siteTitle : NSLocalizedStringFromTable(@"activity.unknown-site", @"Activities", @"Unknown Site");
}

- (NSString *)custom0
{
    return _custom0 ? _custom0 : @"";
}

- (NSString *)custom1
{
    return _custom1 ? _custom1 : @"";
}

- (NSString *)secondFullName
{
    return _secondFullName ? _secondFullName : NSLocalizedStringFromTable(@"activity.unknown-user", @"Activities", @"Unknown User");
}

- (void)parseActivityEntry
{
    if (!self.activityEntry)
    {
        return;
    }
    
    NSDictionary *summary = self.activityEntry.data;
    
    self.title = summary[kActivitySummaryTitle];
    self.fullName = [self fullNameFromFirstName:summary[kActivitySummaryFirstName] lastName:summary[kActivitySummaryLastName]];
    // TODO: Resolve this into a site title
    self.siteTitle = self.activityEntry.siteShortName;
    self.avatarUserName = self.activityEntry.createdBy;
    
    self.custom0 = summary[kActivitySummaryCustom0];
    self.custom1 = summary[kActivitySummaryCustom1];
    self.suppressSite = [[self.class suppressedSiteTypes] containsObject:self.activityEntry.type];
    
    NSString *type = self.activityEntry.type;
    
    if ([type isEqualToString:@"org.alfresco.site.group-added"] ||
        [type isEqualToString:@"org.alfresco.site.group-removed"] ||
        [type isEqualToString:@"org.alfresco.site.group-role-changed"])
    {
        self.fullName = [summary[kActivitySummaryGroupName] stringByReplacingOccurrencesOfString:@"GROUP_" withString:@""];
        self.custom0 = NSLocalizedStringFromTable([@"activity.role." stringByAppendingString:summary[kActivitySummaryRole]], @"Activities", @"Role");
        
    }
    else if ([type isEqualToString:@"org.alfresco.site.user-joined"] ||
             [type isEqualToString:@"org.alfresco.site.user-left"] ||
             [type isEqualToString:@"org.alfresco.site.user-role-changed"])
    {
        self.avatarUserName = summary[kActivitySummaryMemberPersonId] ? summary[kActivitySummaryMemberPersonId] : summary[kActivitySummaryMemberUserName];
        self.fullName = [self fullNameFromFirstName:summary[kActivitySummaryMemberFirstName] lastName:summary[kActivitySummaryMemberLastName]];
        self.custom0 = NSLocalizedStringFromTable([@"activity.role." stringByAppendingString:summary[kActivitySummaryRole]], @"Activities", @"Role");
    }
    else if ([type isEqualToString:@"org.alfresco.site.liked"] ||
             [type isEqualToString:@"org.alfresco.subscriptions.followed"])
    {
        self.fullName = [self fullNameFromFirstName:summary[kActivitySummaryFollowerFirstName] lastName:summary[kActivitySummaryFollowerLastName]];
        self.secondFullName = [self fullNameFromFirstName:summary[kActivitySummaryUserFirstName] lastName:summary[kActivitySummaryUserLastName]];
    }
    else if ([type isEqualToString:@"org.alfresco.subscriptions.subscribed"])
    {
        self.fullName = [self fullNameFromFirstName:summary[kActivitySummarySubscriberFirstName] lastName:summary[kActivitySummarySubscriberLastName]];
        // This looks like it will be a nodeRef, but also doesn't seem to be supported in Share yet.
        self.custom0 = summary[kActivitySummaryNode];
    }
    else if ([type isEqualToString:@"org.alfresco.profile.status-changed"])
    {
        self.custom0 = summary[kActivitySummaryStatus];
    }
}

- (void)renderActivityLabels
{
    // 0 = Item title / page link, 1 = User profile link, 2 = custom0, 3 = custom1, 4 = Site link, 5 = second user profile link
    NSArray *detailTokenValues = @[self.title, self.fullName, self.custom0, self.custom1, self.siteTitle, self.secondFullName];
    
    self.attributedDetailString = [self attributedStringForTemplate:NSLocalizedStringFromTable(self.activityEntry.type, @"Activities", @"Activity template string") withReplacements:detailTokenValues];
    self.detailString = [self.attributedDetailString string];
    self.dateString = relativeDateFromDate(self.activityEntry.createdAt);
}

- (NSString *)fullNameFromFirstName:(NSString *)firstName lastName:(NSString *)lastName
{
    return [[NSString stringWithFormat:@"%@ %@", firstName, lastName] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (NSAttributedString *)attributedStringForTemplate:(NSString *)template withReplacements:(NSArray *)replacements
{
    // Base format attributes
    NSDictionary *baseAttributes = @{ NSForegroundColorAttributeName: [UIColor darkGrayColor] };
    NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:template attributes:baseAttributes];
    
    // Token replacement format attributes
    NSDictionary *tokenAttributes = @{ NSForegroundColorAttributeName: [UIColor blackColor] };
    
    for (NSInteger index = 0; index < replacements.count; index++)
    {
        NSString *indexString = [NSString stringWithFormat:@"{%@}", @(index)];
        NSRange indexRange = [[attrString string] rangeOfString:indexString];
        
        if (indexRange.location != NSNotFound)
        {
            NSAttributedString *tokenString = [[NSAttributedString alloc] initWithString:replacements[index] attributes:tokenAttributes];
            [attrString replaceCharactersInRange:indexRange withAttributedString:tokenString];
        }
    }
    
    return attrString;
}

@end
