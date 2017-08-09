#import <objc/runtime.h>
#import <notify.h>
#import <Security/Security.h>
#import <substrate.h>

extern const char *__progname;

#define NSLog(...)

#define PLIST_PATH_Settings "/var/mobile/Library/Preferences/com.julioverne.goodwifi.plist"

static BOOL Enabled;
static BOOL showKnowNetworks;
static BOOL removeRSSILimit;
static BOOL showMacAddress;

static NSString* getPasswordForNetworkName(NSString* networkName)
{
	@autoreleasepool {
		if(!networkName) {
			return nil;
		}
		NSMutableDictionary *query = [NSMutableDictionary dictionary];
		[query setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
		[query setObject:(__bridge id)@"AirPort" forKey:(__bridge id)kSecAttrService];
		[query setObject:networkName forKey:(__bridge id)kSecAttrAccount];
		[query setObject:(__bridge id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];
		CFTypeRef result = NULL;
		OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
		if (status != errSecSuccess) {
			return nil;
		}
		return [[NSString alloc] initWithData:(NSData *)result encoding:NSASCIIStringEncoding];
	}
}

enum {
	kCWSecurityNone                 = 0,
	kCWSecurityWEP                  = 1,
	kCWSecurityWPAPersonal          = 2,
	kCWSecurityWPAPersonalMixed     = 3,
	kCWSecurityWPA2Personal         = 4,
	kCWSecurityPersonal             = 5,
	kCWSecurityDynamicWEP           = 6,
	kCWSecurityWPAEnterprise        = 7,
	kCWSecurityWPAEnterpriseMixed   = 8,
	kCWSecurityWPA2Enterprise       = 9,
	kCWSecurityEnterprise           = 10,
	kCWSecurityUnknown              = NSIntegerMax,
};

static NSString* stringForSecurityMode(int securityMode)
{
	NSString *securityModeStr = nil;
	switch(securityMode)
	{
		case kCWSecurityNone:
			securityModeStr = nil;
			break;
		case kCWSecurityWEP:
			securityModeStr = @"WEP";
			break;
		case kCWSecurityWPAPersonal:
			securityModeStr = @"WPA-PSK";
			break;
		case kCWSecurityWPAPersonalMixed:
			securityModeStr = @"WPA-PSK/Mix";
			break;
		case kCWSecurityWPA2Personal:
			securityModeStr = @"WPA2-PSK";
			break;
		case kCWSecurityPersonal:
			securityModeStr = @"PSK";
			break;
		case kCWSecurityDynamicWEP:
			securityModeStr = @"WEP/Dync";
			break;
		case kCWSecurityWPAEnterprise:
			securityModeStr = @"WPA";
			break;
		case kCWSecurityWPAEnterpriseMixed:
			securityModeStr = @"WPA/Mix";
			break;
		case kCWSecurityWPA2Enterprise:
			securityModeStr = @"WPA2";
			break;
		case kCWSecurityEnterprise:
			securityModeStr = @"WPA";
			break;
	}
	return securityModeStr;
}

@interface APNetworksController : NSObject
-(void)scanForNetworks:(id)arg1;
- (void)GoodWiFiFixWiFiManager;
- (void)reloadSpecifiers;
@end
@interface WiFiNetwork : NSObject
- (NSDictionary*)dictionary;
- (NSString*)BSSID;
- (NSString*)ip;
- (int)securityMode;
@end
@interface APTableCell : UITableViewCell {
	UIImageView* _lockView;
	UIImageView* _barsView;
}
@property (nonatomic,retain) UILabel* labelRssi;
@property (nonatomic,retain) UILabel* labelCan;
@property (nonatomic,retain) UILabel* labelSec;
@property (nonatomic,retain) WiFiNetwork * network;
-(void)setDetailText:(id)arg1 ;
@end




%hook APTableCell
%property (nonatomic, retain) id labelRssi;
%property (nonatomic, retain) id labelCan;
%property (nonatomic, retain) id labelSec;
-(void)__layoutNetwork
{
	%orig;
	
	if(UIView* tabVi = [self.contentView viewWithTag:4455]) {
		[tabVi removeFromSuperview];
	}
	if(UIView* tabVi = [self.contentView viewWithTag:4456]) {
		[tabVi removeFromSuperview];
	}
	if(UIView* tabVi = [self.contentView viewWithTag:4457]) {
		[tabVi removeFromSuperview];
	}
	if(Enabled&&self.network) {
		
		[self setDetailText:showMacAddress?[self.network ip].length>0?[self.network ip]:[self.network BSSID]:@""];
		
		UIImageView* _barsView = MSHookIvar<UIImageView*>(self, "_barsView");
		UIImageView* _lockView = MSHookIvar<UIImageView*>(self, "_lockView");
		
		if(_lockView) {
			if(!self.labelSec) {
				self.labelSec = [[UILabel alloc] init];
				self.labelSec.tag = 4455;
			}
			self.labelSec.center = _lockView.center;
			self.labelSec.frame = CGRectMake(self.labelSec.frame.origin.x, self.labelSec.frame.origin.y + self.labelSec.frame.size.height + 3, 30, 8);
			[self.labelSec setText:stringForSecurityMode([self.network securityMode])];
			[self.labelSec setBackgroundColor:[UIColor clearColor]];
			[self.labelSec setNumberOfLines:0];
			self.labelSec.font = [UIFont systemFontOfSize:7];
			self.labelSec.textAlignment = NSTextAlignmentCenter;
			self.labelSec.adjustsFontSizeToFitWidth = YES;
			[self.contentView addSubview:self.labelSec];
		}
		
		if(_barsView) {
			if(!self.labelRssi) {
				self.labelRssi = [[UILabel alloc] init];
				self.labelRssi.tag = 4456;
			}
			self.labelRssi.center = _barsView.center;
			self.labelRssi.frame = CGRectMake(self.labelRssi.frame.origin.x, self.labelRssi.frame.origin.y + (self.labelRssi.frame.size.height - 3), 20, 8);
			NSString* rssiSignal = nil;
			@try {
				rssiSignal = [[self.network dictionary][@"wifi--setup"][@"RSSI"] stringValue];
			} @catch(NSException* ex) {
				
			}
			[self.labelRssi setText:rssiSignal];
			[self.labelRssi setBackgroundColor:[UIColor clearColor]];
			[self.labelRssi setNumberOfLines:0];
			self.labelRssi.font = [UIFont systemFontOfSize:7];
			self.labelRssi.textAlignment = NSTextAlignmentCenter;
			self.labelRssi.adjustsFontSizeToFitWidth = YES;
			[self.contentView addSubview:self.labelRssi];
			
			if(!self.labelCan) {
				self.labelCan = [[UILabel alloc] init];
				self.labelCan.tag = 4457;
			}
			self.labelCan.center = _barsView.center;
			self.labelCan.frame = CGRectMake(self.labelCan.frame.origin.x, self.labelCan.frame.origin.y - (_barsView.frame.size.height + 5), 32, 8);
			NSString* canNumber = nil;
			@try {
				canNumber = [[self.network dictionary][@"wifi--setup"][@"CHANNEL"] stringValue];
				if(canNumber) {
					canNumber = [NSString stringWithFormat:@"Ch: %@", canNumber];
				}
			} @catch(NSException* ex) {
				
			}
			[self.labelCan setText:canNumber];
			[self.labelCan setBackgroundColor:[UIColor clearColor]];
			[self.labelCan setNumberOfLines:0];
			self.labelCan.font = [UIFont systemFontOfSize:7];
			self.labelCan.textAlignment = NSTextAlignmentCenter;
			self.labelCan.adjustsFontSizeToFitWidth = YES;
			[self.contentView addSubview:self.labelCan];
		}
	}
}
%end

%hook APNetworksController
%new
- (void)GoodWiFiFixWiFiManager
{
	static __strong UIRefreshControl *refreshControl;
	if(!refreshControl) {
		refreshControl = [[UIRefreshControl alloc] init];
		[refreshControl addTarget:self action:@selector(refreshScan:) forControlEvents:UIControlEventValueChanged];
		refreshControl.tag = 8654;
	}	
	if(UITableView* tableV = (UITableView *)object_getIvar(self, class_getInstanceVariable([self class], "_table"))) {
		if(UIView* rem = [tableV viewWithTag:8654]) {
			[rem removeFromSuperview];
		}
		[tableV addSubview:refreshControl];
	}
	if(id _manager = MSHookIvar<id>(self, "_manager")) {
		MSHookIvar<int>(_manager, "_rssiThreshold") = Enabled&&removeRSSILimit?(-1000):(-80);
		MSHookIvar<BOOL>(_manager, "_showKnownNetworksUI") = Enabled&&showKnowNetworks?YES:NO;
	}
}
%new
- (void)refreshScan:(UIRefreshControl *)refresh
{
	[self scanForNetworks:nil];
	[refresh endRefreshing];
}
-(void)scanForNetworks:(id)arg1
{
	[self GoodWiFiFixWiFiManager];
	%orig;
}
- (void)viewWillAppear:(BOOL)arg1
{
	%orig;
	[self GoodWiFiFixWiFiManager];
	[self reloadSpecifiers];
}
%end

%hook APKnownNetworksController
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell* cell = %orig;
	if(cell.textLabel) {
		cell.detailTextLabel.text = getPasswordForNetworkName(cell.textLabel.text);
	}
	return cell;	
}
%end




static void settingsChangedGoodWiFi(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo)
{
	@autoreleasepool {
		NSDictionary *Prefs = [[[NSDictionary alloc] initWithContentsOfFile:@PLIST_PATH_Settings]?:@{} copy];
		Enabled = (BOOL)[Prefs[@"Enabled"]?:@YES boolValue];
		showKnowNetworks = (BOOL)[Prefs[@"showKnowNetworks"]?:@YES boolValue];
		removeRSSILimit = (BOOL)[Prefs[@"removeRSSILimit"]?:@YES boolValue];
		showMacAddress = (BOOL)[Prefs[@"showMacAddress"]?:@YES boolValue];
	}
}

%ctor
{
	@autoreleasepool {
		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, settingsChangedGoodWiFi, CFSTR("com.julioverne.goodwifi/SettingsChanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);
		settingsChangedGoodWiFi(NULL, NULL, NULL, NULL, NULL);
		dlopen("/System/Library/PreferenceBundles/AirPortSettings.bundle/AirPortSettings", RTLD_LAZY);
	}
}
