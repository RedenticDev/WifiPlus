#import <UIKit/UIKit.h>

#define PRIVATE_WIFI_BUNDLE @"/System/Library/PrivateFrameworks/WiFiKitUI.framework/"
#define PREFS_PATH @"/var/mobile/Library/Preferences/dev.redentic.wifiplus.plist"
#define localize(key, table, bundle) NSLocalizedStringFromTableInBundle(key, table, [NSBundle bundleWithPath:bundle], nil)

// Existing keys
static NSString *const kWFLocKnownNetworksTitle = @"kWFLocKnownNetworksTitle";
static NSString *const kWFLocKnownSectionTitle = @"kWFLocKnownSectionTitle";

// Prefs
static NSMutableDictionary *prefs;

// Headers
@interface WFAirportViewController : UIViewController
@end

@interface WFKnownNetworksViewController : UITableViewController
@end

// New class
@interface WFPSettingsViewController : UITableViewController
@property (nonatomic, strong) UIViewController *presentingVC;
@property (nonatomic, assign) BOOL needsToPop;
- (void)dismissSettings:(id)sender;
- (void)switchToggled:(UISwitch *)sender;
@end
