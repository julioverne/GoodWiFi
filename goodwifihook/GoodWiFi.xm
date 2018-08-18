#import "GoodWiFi.h"

#define PLIST_PATH_Settings "/var/mobile/Library/Preferences/com.julioverne.goodwifi.plist"

static BOOL Enabled;
static BOOL showKnowNetworks;
static BOOL removeRSSILimit;
static BOOL showMacAddress;

static NSMutableDictionary *cachedPasswords;
static NSMutableDictionary *cachedNetworks;

static NSString* getPassForNetworkName(NSString* networkName)
{
	if(networkName) {
		if (cachedPasswords[networkName])
			return cachedPasswords[networkName];
		if(WiFiManagerRef manager = WiFiManagerClientCreate(kCFAllocatorDefault, 0)) {
			if(CFArrayRef networks = WiFiManagerClientCopyNetworks(manager)) {
				for(id networkNow in (NSArray*)networks) {
					if(CFStringRef name = WiFiNetworkGetSSID((WiFiNetworkRef)networkNow)) {
						if([(NSString*)name isEqualToString:networkName]) {
							if(CFStringRef pass = WiFiNetworkCopyPassword((WiFiNetworkRef)networkNow)) {
								return cachedPasswords[networkName] = [NSString stringWithFormat:@"%@", pass];
							}
							break;
						}
					}					
				}
			}
		}
	}
	return nil;
}

static NSString* getPassForNetworkAtIndex(int Index)
{
	if(WiFiManagerRef manager = WiFiManagerClientCreate(kCFAllocatorDefault, 0)) {
		if(CFArrayRef networks = WiFiManagerClientCopyNetworks(manager)) {
			if(CFStringRef pass = WiFiNetworkCopyPassword((WiFiNetworkRef)((NSArray*)networks)[Index])) {
				return [NSString stringWithFormat:@"%@", pass];
			}
		}
	}
	return nil;
}

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

%group iOS10

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
		
		[self setDetailText:showMacAddress?/*[self.network ip].length>0?[self.network ip]:*/[self.network BSSID]:@""];
		
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
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell* cell = %orig;
	if(cell) {
		PSSpecifier* powerWIFI = MSHookIvar<PSSpecifier*>(self, "_powerSpecifier");
		if(indexPath == [self indexPathForSpecifier:powerWIFI]) {			
			cell.detailTextLabel.text = nil;			
			PSSpecifier* currentNetwork = MSHookIvar<PSSpecifier*>(self, "_currentNetworkSpecifier");
			if(currentNetwork) {
				if(NSDictionary* userInfoNet = [currentNetwork userInfo]) {
					if(WiFiNetwork* network = userInfoNet[@"wifi-network"]) {
						cell.detailTextLabel.text = [network ip].length>0?[network ip]:nil;
					}
				}
			}
		}
	}
	return cell;	
}
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
    if (action == @selector(copy:)) {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        UIPasteboard *pasteBoard = [UIPasteboard generalPasteboard];
        [pasteBoard setString:cell.detailTextLabel.text];
    }
}	
%end

%end // end Group iOS10



%group iOS11



static NSArray* networksList;
static WFNetworkScanRecord* currNetwork;

static WFNetworkScanRecord* networkForName(NSString* name)
{
	if(networksList) {
		if (cachedNetworks[name])
			return cachedNetworks[name];
		for(WFNetworkScanRecord* netNow in networksList) {
			if(netNow.ssid && [netNow.ssid isEqualToString:name]) {
				return cachedNetworks[name] = netNow;
			}
		}
	}
	if(currNetwork) {
		if(currNetwork.ssid && [currNetwork.ssid isEqualToString:name]) {
			return cachedNetworks[name] = currNetwork;
		}
	}
	return nil;
}

%hook WFNetworkListCell
%property (nonatomic, retain) id labelRssi;
%property (nonatomic, retain) id labelCan;
%property (nonatomic, retain) id labelSec;
%property (nonatomic,retain) id network;

static void updateSubtitle(WFNetworkListCell *self) {
	if(Enabled && showMacAddress) {
		self.network = networkForName(self.title);
		[self setSubtitle:self.network.bssid];
	}
}

static void updateLockImageView(WFNetworkListCell *self) {
	UIImageView* _lockView = MSHookIvar<UIImageView*>(self, "_lockImageView");
	if(Enabled && _lockView) {
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
}

static void updateSignalImageView(WFNetworkListCell *self) {
	UIImageView* _barsView = MSHookIvar<UIImageView*>(self, "_signalImageView");
	if(Enabled && _barsView) {
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

- (void)setTitle:(NSString *)title {
	%orig;
	updateSubtitle(self);
}

- (void)setLockImageView:(UIImageView *)_lockView {
	%orig;
	updateLockImageView(self);
}

- (void)setSignalImageView:(UIImageView *)_barsView {
	%orig;
	updateSignalImageView(self);
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
		NSLog(@"setNetworks: %@", arg1);
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
			if (cachedNetworks[cell.textLabel.text])
				cell.network = cachedNetworks[cell.textLabel.text];
			else {
				for(WFNetworkScanRecord* netNow in networksList) {
					if(netNow.ssid && [netNow.ssid isEqualToString:cell.textLabel.text]) {
						cell.network = cachedNetworks[cell.textLabel.text] = netNow;
						break;
					}
				}
			}
		}
		updateSubtitle(cell);
		updateLockImageView(cell);
		updateSignalImageView(cell);
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
		UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        UIPasteboard *pasteBoard = [UIPasteboard generalPasteboard];
        [pasteBoard setString:getPassForNetworkName(cell.textLabel.text)?:@""];
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
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        UIPasteboard *pasteBoard = [UIPasteboard generalPasteboard];
        [pasteBoard setString:cell.detailTextLabel.text];
    }
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return self.password && section == [self numberOfSectionsInTableView:tableView] - 1 ? 1 : %orig;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return self.password ? %orig + 1 : %orig;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (self.password && indexPath.section == [self numberOfSectionsInTableView:tableView] - 1) {
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MyIdentifier"];
    	if (cell == nil) {
        	cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"MyIdentifier"] autorelease];
			cell.textLabel.text = @"Password";
			cell.detailTextLabel.text = self.password;
    	}
		return cell;
	}
	return %orig;
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
		cachedPasswords = [[NSMutableDictionary dictionary] retain];
		cachedNetworks = [[NSMutableDictionary dictionary] retain];
		if(kCFCoreFoundationVersionNumber >= 1443.00) { // >= 11.0
			%init(iOS11);
		} else {
			%init(iOS10);
		}
	}
}
