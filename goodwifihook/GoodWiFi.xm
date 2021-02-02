#import "GoodWiFi.h"


#define NSLog1(...)

#define PLIST_PATH_Settings "/var/mobile/Library/Preferences/com.julioverne.goodwifi.plist"

static BOOL Enabled;
static BOOL showKnowNetworks;
static BOOL removeRSSILimit;
static BOOL showMacAddress;


static WiFiManagerRef wifiManager()
{
	static WiFiManagerRef manager;
	if(!manager) {
		manager = WiFiManagerClientCreate(kCFAllocatorDefault, 0);
	}
	return manager;
}

static CFArrayRef networksListArr()
{
	static time_t lastTime;
	static CFArrayRef networks;
	if(networks && (([[NSDate date] timeIntervalSince1970]-lastTime) > 5) ) { // 5secs refetch timeout
		CFRelease(networks);
		networks = nil;
	}
	if(!networks) {
		lastTime = [[NSDate date] timeIntervalSince1970];
		networks = WiFiManagerClientCopyNetworks(wifiManager());
	}
	return networks;
}

static NSString* getPassForNetworkName(NSString* networkName)
{
	NSString* passwordRet = nil;
	@try {
		if(networkName) {
			if(CFArrayRef networks = networksListArr()) {
				for(id networkNow in (__bridge NSArray*)networks) {
					if(CFStringRef name = WiFiNetworkGetSSID((__bridge WiFiNetworkRef)networkNow)) {
						if([(__bridge NSString*)name isEqualToString:networkName]) {
							if(CFStringRef pass = WiFiNetworkCopyPassword((__bridge WiFiNetworkRef)networkNow)) {
								passwordRet = [NSString stringWithFormat:@"%@", pass];
								CFRelease(pass);
							}
							break;
						}
					}					
				}
			}
		}
	} @catch(NSException* ex) {
	}
	return passwordRet;
}

static NSString* getPassForNetworkAtIndex(int Index)
{
	NSString* passwordRet = nil;
	@try {
		if(CFArrayRef networks = networksListArr()) {
			if(CFStringRef pass = WiFiNetworkCopyPassword((__bridge WiFiNetworkRef)((__bridge NSArray*)networks)[Index])) {
				passwordRet = [NSString stringWithFormat:@"%@", pass];
				CFRelease(pass);
			}
		}
	} @catch(NSException* ex) {
	}
	return passwordRet;
}

static NSString* stringForSecurityMode(int securityMode)
{
	switch(securityMode)
	{
		case kCWSecurityNone:
			return nil;
		case kCWSecurityWEP:
			return @"WEP";
		case kCWSecurityWPAPersonal:
			return @"WPA-PSK";
		case kCWSecurityWPAPersonalMixed:
			return @"WPA-PSK/Mix";
		case kCWSecurityWPA2Personal:
			return @"WPA2-PSK";
		case kCWSecurityPersonal:
			return @"PSK";
		case kCWSecurityDynamicWEP:
			return @"WEP/Dync";
		case kCWSecurityWPAEnterprise:
			return @"WPA";
		case kCWSecurityWPAEnterpriseMixed:
			return @"WPA/Mix";
		case kCWSecurityWPA2Enterprise:
			return @"WPA2";
		case kCWSecurityEnterprise:
			return @"WPA";
	}
	return nil;
}

%group iOS10

%hook APTableCell
%property (nonatomic, retain) id labelRssi;
%property (nonatomic, retain) id labelCan;
%property (nonatomic, retain) id labelSec;
-(void)__layoutNetwork
{
	%orig;
	
	@try {
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
			
			[self setDetailText:showMacAddress?/*[self.network ip].length>0?[self.network ip]:*/[self.network BSSID]:@""];
			
			UIImageView* _barsView = (UIImageView *)object_getIvar(self, class_getInstanceVariable([self class], "_barsView"));
			UIImageView* _lockView = (UIImageView *)object_getIvar(self, class_getInstanceVariable([self class], "_lockView"));
			
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
	} @catch(NSException* ex) {
	}
}
%end

%hook APNetworksController
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell* cell = %orig;
	@try {
		if(cell) {
			
			PSSpecifier* powerWIFI = (PSSpecifier *)object_getIvar(self, class_getInstanceVariable([self class], "_powerSpecifier"));
			
			if(indexPath == [self indexPathForSpecifier:powerWIFI]) {			
				cell.detailTextLabel.text = nil;
				PSSpecifier* currentNetwork = (PSSpecifier *)object_getIvar(self, class_getInstanceVariable([self class], "_currentNetworkSpecifier"));
				if(currentNetwork) {
					if(NSDictionary* userInfoNet = [currentNetwork userInfo]) {
						if(WiFiNetwork* network = userInfoNet[@"wifi-network"]) {
							cell.detailTextLabel.text = [network ip].length>0?[network ip]:nil;
						}
					}
				}
			}
		}
	} @catch(NSException* ex) {
	}
	return cell;	
}
%new
- (void)GoodWiFiFixWiFiManager
{
	@try {
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
		if(id _manager = (id)object_getIvar(self, class_getInstanceVariable([self class], "_manager"))) {
			MSHookIvar<int>(_manager, "_rssiThreshold") = Enabled&&removeRSSILimit?(-1000):(-80);
			MSHookIvar<BOOL>(_manager, "_showKnownNetworksUI") = Enabled&&showKnowNetworks?YES:NO;
		}
	} @catch(NSException* ex) {
	}
}
%new
- (void)refreshScan:(UIRefreshControl *)refresh
{
	[self stopScanning];
	[self scanForNetworks:nil];
	[refresh endRefreshing];
}
- (void)scanForNetworks:(id)arg1
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
- (void)viewDidLayoutSubviews
{
	%orig;
	if(UITableView* tableV = (UITableView *)object_getIvar(self, class_getInstanceVariable([self class], "_table"))) {
		[tableV reloadData];
	}
}
%end

%hook APKnownNetworksController
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell* cell = %orig;
	cell.detailTextLabel.text = getPassForNetworkAtIndex(indexPath.row)?:@"";
	return cell;	
}
%new
- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}
%new
- (BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    return (action == @selector(copy:));
}
%new
- (void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    if(action == @selector(copy:)) {
		@try {
			UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
			if(cell) {
				[[UIPasteboard generalPasteboard] setString:cell.detailTextLabel.text];
			}
		} @catch(NSException* ex) {
		}
    }
}	
%end

%end // end Group iOS10



%group iOS11



static NSArray* networksList;
static WFNetworkScanRecord* currNetwork;

static WFNetworkScanRecord* networkForName(NSString* name)
{
	@try {
		if(networksList) {
			for(WFNetworkScanRecord* netNow in networksList) {
				if(netNow.ssid && [netNow.ssid isEqualToString:name]) {
					return netNow;
				}
			}
		}
		if(currNetwork) {
			if(currNetwork.ssid && [currNetwork.ssid isEqualToString:name]) {
				return currNetwork;
			}
		}
	} @catch(NSException* ex) {
	}
	return nil;
}

%hook WFNetworkListCell
%property (nonatomic, retain) id labelRssi;
%property (nonatomic, retain) id labelCan;
%property (nonatomic, retain) id labelSec;
%property (nonatomic,retain) id network;
- (void)layoutSubviews
{
	@try {
		self.network = networkForName(self.title);
		if(Enabled&&self.network) {
			if(showMacAddress) {
				[self setSubtitle:self.network.bssid];
			}
			
			UIImageView* _barsView = (UIImageView *)object_getIvar(self, class_getInstanceVariable([self class], "_signalImageView"));
			UIImageView* _lockView = (UIImageView *)object_getIvar(self, class_getInstanceVariable([self class], "_lockImageView"));
		
			if(_lockView) {
				if(!self.labelSec) {
					self.labelSec = (UILabel *)[_lockView viewWithTag:4455]?:[[UILabel alloc] init];
					self.labelSec.tag = 4455;
				}
				[self.labelSec setText:nil];
				self.labelSec.center = _lockView.center;
				self.labelSec.frame = CGRectMake((0 - (30 / 3)), _lockView.frame.size.height + 2, 30, 8);
				[self.labelSec setText:stringForSecurityMode([self.network securityMode])];
				[self.labelSec setBackgroundColor:[UIColor clearColor]];
				[self.labelSec setNumberOfLines:0];
				self.labelSec.font = [UIFont systemFontOfSize:7];
				self.labelSec.textAlignment = NSTextAlignmentCenter;
				self.labelSec.adjustsFontSizeToFitWidth = YES;
				if([_lockView viewWithTag:4455]==nil) {
					[_lockView addSubview:self.labelSec];
				}
			}
			
			if(_barsView) {
				if(!self.labelRssi) {
					self.labelRssi = (UILabel *)[_barsView viewWithTag:4456]?:[[UILabel alloc] init];
					self.labelRssi.tag = 4456;
				}
				[self.labelRssi setText:nil];
				self.labelRssi.center = _barsView.center;
				self.labelRssi.frame = CGRectMake(0, _barsView.frame.size.height - 5, _barsView.frame.size.width, 8);
				NSString* rssiSignal = nil;
				@try {
					rssiSignal = [@([self.network rssi]) stringValue];
				} @catch(NSException* ex) {
					
				}
				[self.labelRssi setText:rssiSignal];
				[self.labelRssi setBackgroundColor:[UIColor clearColor]];
				[self.labelRssi setNumberOfLines:0];
				self.labelRssi.font = [UIFont systemFontOfSize:7];
				self.labelRssi.textAlignment = NSTextAlignmentCenter;
				self.labelRssi.adjustsFontSizeToFitWidth = YES;
				if([_barsView viewWithTag:4456]==nil) {
					[_barsView addSubview:self.labelRssi];
				}
				
				if(!self.labelCan) {
					self.labelCan = (UILabel *)[_barsView viewWithTag:4457]?:[[UILabel alloc] init];
					self.labelCan.tag = 4457;
				}
				[self.labelCan setText:nil];
				self.labelCan.center = _barsView.center;
				self.labelCan.frame = CGRectMake(0, 0 - 2, _barsView.frame.size.width, 8);
				NSString* canNumber = nil;
				@try {
					canNumber = [[self.network channel] stringValue];
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
				if([_barsView viewWithTag:4457]==nil) {
					[_barsView addSubview:self.labelCan];
				}
			}
		
		}
	}@catch(NSException* ex) {
	}
	
	%orig;
	
}
%end

static WFNetworkListController* currDelegate;

%hook WFAirportViewController
-(void)setListDelegate:(id)arg1
{
	currDelegate = arg1;
	%orig;
}
-(void)setNetworks:(NSSet*)arg1
{
	@try {
		networksList = arg1?[[arg1 allObjects] copy]:nil;
	}@catch(NSException* ex) {
	}
	%orig;
}
- (void)viewWillAppear:(BOOL)arg1
{
	%orig;
	static __strong UIRefreshControl *refreshControl;
		//if(!refreshControl) {
			refreshControl = [[UIRefreshControl alloc] init];
			[refreshControl addTarget:self action:@selector(refreshScan:) forControlEvents:UIControlEventValueChanged];
			refreshControl.tag = 8654;
		//}
		if(UITableView* tableV = self.tableView) {
			if(UIView* rem = [tableV viewWithTag:8654]) {
				[rem removeFromSuperview];
			}
			[tableV addSubview:refreshControl];
		}
}
%new
- (void)refreshScan:(UIRefreshControl *)refresh
{
	@try {
		[currDelegate stopScanning];
		[currDelegate startScanning];
	}@catch(NSException* ex) {
	}
	[refresh endRefreshing];
}
- (WFNetworkListCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	WFNetworkListCell* cell = %orig;
	@try {
		cell.network = nil;
		if(indexPath == [self _currentNetworkCellIndexPath]) {
			currNetwork = [self currentNetwork];
			cell.network = currNetwork;
		} else if(networksList && indexPath.section == 1) {
			for(WFNetworkScanRecord* netNow in networksList) {
				if(netNow.ssid && [netNow.ssid isEqualToString:cell.textLabel.text]) {
					cell.network = netNow;
					break;
				}
			}
		}
	}@catch(NSException* ex) {
	}
	return cell;
}
%end


%hook WFClient
- (BOOL)isKnownNetworkUIEnabled
{
	if(Enabled&&showKnowNetworks) {
		return YES;
	}
	return %orig;
}
%end

%hook WFScanRequest
- (BOOL)applyRssiThresholdFilter
{
	if(Enabled&&removeRSSILimit) {
		return NO;
	}
	return %orig;
}
%end

%hook WFKnownNetworksViewController
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell* cell = %orig;
	@try {
		if(UIView* rem = [cell.contentView viewWithTag:6532]) {
			[rem removeFromSuperview];
		}
		UILabel *countLabel= [[UILabel alloc] init];
		countLabel.tag = 6532;
		countLabel.backgroundColor = [UIColor clearColor];
		[countLabel setFrame:CGRectMake(0 ,0, 180,20)];
		countLabel.numberOfLines = 0;
		countLabel.font = [UIFont systemFontOfSize:11];
		countLabel.textColor = [UIColor grayColor];
		countLabel.textAlignment = NSTextAlignmentRight;
		[cell.contentView addSubview:countLabel];
		
		[countLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
		
		NSDictionary *viewDict = NSDictionaryOfVariableBindings(countLabel);
		[cell addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[countLabel]-0-|" options:NSLayoutFormatDirectionLeftToRight metrics:nil views:viewDict]];
		[cell addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[countLabel]-20-|" options:NSLayoutFormatDirectionLeftToRight metrics:nil views:viewDict]];
		[countLabel addConstraint:[NSLayoutConstraint constraintWithItem:countLabel attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:countLabel attribute:NSLayoutAttributeHeight multiplier:1.0 constant:0.0]];
		countLabel.text = getPassForNetworkName(cell.textLabel.text)?:@"";
	} @catch(NSException* ex) {
	}
	
	return cell;	
}
%new
- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}
%new
- (BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    return (action == @selector(copy:));
}
%new
- (void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    if (action == @selector(copy:)) {
		@try {
			UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
			UIPasteboard *pasteBoard = [UIPasteboard generalPasteboard];
			[pasteBoard setString:getPassForNetworkName(cell.textLabel.text)?:@""];
		} @catch(NSException* ex) {
		}
    }
}	
%end

%hook WFKnownNetworkDetailsViewController
%new
- (BOOL)tableView:(UITableView *)tableView shouldShowMenuForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}
%new
- (BOOL)tableView:(UITableView *)tableView canPerformAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    return (action == @selector(copy:));
}
%new
- (void)tableView:(UITableView *)tableView performAction:(SEL)action forRowAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender
{
    if (action == @selector(copy:)) {
		@try {
			UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
			UIPasteboard *pasteBoard = [UIPasteboard generalPasteboard];
			[pasteBoard setString:cell.detailTextLabel.text];
		} @catch(NSException* ex) {
		}
    }
}	
%end

%end // end Group iOS11



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
		dlopen("/System/Library/PrivateFrameworks/WiFiKit.framework/WiFiKit", RTLD_LAZY);
		dlopen("/System/Library/PrivateFrameworks/WiFiKitUI.framework/WiFiKitUI", RTLD_LAZY);
		if(kCFCoreFoundationVersionNumber >= 1443.00) { // >= 11.0
			%init(iOS11);
		} else {
			%init(iOS10);
		}
	}
}
