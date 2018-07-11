#import <objc/runtime.h>
#import <notify.h>
#import <Security/Security.h>
#import <substrate.h>

#import <prefs.h>

extern const char *__progname;

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

typedef struct __WiFiNetwork *WiFiNetworkRef;
typedef struct __WiFiManager *WiFiManagerRef;

extern "C" WiFiManagerRef WiFiManagerClientCreate(CFAllocatorRef allocator, int flags);
extern "C" CFArrayRef WiFiManagerClientCopyNetworks(WiFiManagerRef manager);
extern "C" CFStringRef WiFiNetworkCopyPassword(WiFiNetworkRef);
extern "C" CFStringRef WiFiNetworkGetSSID(WiFiNetworkRef network);

@interface APNetworksController : PSListController
- (void)scanForNetworks:(id)arg1;
- (void)stopScanning;
- (void)GoodWiFiFixWiFiManager;
- (void)reloadSpecifiers;
@end
@interface WiFiNetwork : NSObject
- (id)initWithWirelessDict:(id)arg1;
- (NSDictionary*)dictionary;
- (NSString*)BSSID;
- (NSString*)ip;
- (NSString*)password;
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

@interface WFNetworkScanRecord : NSObject
@property (nonatomic,copy,readonly) NSString * bssid;
@property (nonatomic,copy,readonly) NSString * ssid;
@property (nonatomic,readonly) long long rssi;
@property (nonatomic,retain) NSNumber * channel; 
@property (assign,nonatomic) long long securityMode;
@property (retain) NSDictionary * attributes;
@end

@interface WFNetworkListCell : UITableViewCell
@property (nonatomic,retain) UILabel* labelRssi;
@property (nonatomic,retain) UILabel* labelCan;
@property (nonatomic,retain) UILabel* labelSec;
@property (nonatomic,retain) WFNetworkScanRecord * network;
@property (nonatomic,copy) NSString * title; 
- (void)setSubtitle:(NSString*)arg1;
@end


@interface WFAirportViewController : UITableViewController
-(id)_currentNetworkCellIndexPath;
-(WFNetworkScanRecord*)currentNetwork;
-(void)refresh;
-(void)setScanning:(BOOL)arg1 ;
-(void)powerStateDidChange:(BOOL)arg1 ;
@end

@interface WFNetworkListController : UITableViewController
-(void)startScanning;
-(void)stopScanning;
@end

