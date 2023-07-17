#import "Headers.h"

/*
FIXME
- [ ] Fix tweak not working without NetworkList lol
- [ ] Fix rare crashes on option toggle (due to NetworkList?)
- [x] Improve readability with large text in prefs cells
- [x] Save settings in file
*/

#pragma mark - Settings
@implementation WFPSettingsViewController

- (instancetype)init {
    if (@available(iOS 13.0, *)) {
        return self = [super initWithStyle:UITableViewStyleInsetGrouped];
    } else {
        return self = [super initWithStyle:UITableViewStyleGrouped];
    }
}

- (void)loadView {
    [super loadView];

    self.title = @"WiFiPlus";
    self.navigationController.navigationBar.prefersLargeTitles = YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    if (@available(iOS 13.0, *)) {
        self.modalInPresentation = YES;
    }
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissSettings:)];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

- (void)dismissSettings:(id)sender {
    // Prefs
    [prefs writeToURL:[NSURL fileURLWithPath:PREFS_PATH] error:nil];
    // Dismiss
    if (!self.presentingVC) {
        [self dismissViewControllerAnimated:YES completion:nil];
        return;
    }
    [self.presentingVC dismissViewControllerAnimated:YES completion:nil];
}

// Delegates
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return section == 0 ? 1 : 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return section == 0 ? @"Diagnostics" : @"Known networks";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.adjustsFontSizeToFitWidth = YES;
    }
    UISwitch *switchView = [[UISwitch alloc] init];
    switchView.tag = indexPath.row + indexPath.section; // don't do that
    switch (switchView.tag) {
        case 0:
            cell.textLabel.text = @"Show 'Diagnostics' section";
            switchView.on = [prefs[@"showDiagnostics"] boolValue];
            break;
        
        case 1:
            cell.textLabel.text = @"Show 'Known networks' section";
            switchView.on = [prefs[@"showKnownNetworks"] boolValue];
            break;
        
        case 2:
            cell.textLabel.text = @"Format known network details";
            switchView.on = [prefs[@"autoLocalize"] boolValue];
            break;
        
        default:
            break;
    }
    [switchView addTarget:self action:@selector(switchToggled:) forControlEvents:UIControlEventValueChanged];
    cell.accessoryView = switchView;

    return cell;
}

- (void)switchToggled:(UISwitch *)sender {
    BOOL value = sender.isOn;
    switch (sender.tag) {
        case 0:
            prefs[@"showDiagnostics"] = @(value);
            self.needsToPop = YES;
            break;
        
        case 1:
            prefs[@"showKnownNetworks"] = @(value);
            self.needsToPop = YES;
            break;
        
        case 2:
            prefs[@"autoLocalize"] = @(value);
            break;
        
        default:
            break;
    }
}

@end

#pragma mark - Tweak
static NSString *autoLocalizedTextForText(NSString *text, BOOL addSpaces) {
    if (!text) return nil;
    if (!prefs[@"autoLocalize"]) return text;

    // Remove prefix
    static NSString *prefix = @"kWFLocKnownNetwork";
    if ([text hasPrefix:prefix]) {
        text = [text stringByReplacingOccurrencesOfString:prefix withString:@""];
    }

    // Remove suffix
    static NSString *suffix = @"Title";
    if ([text hasSuffix:suffix]) {
        text = [text stringByReplacingOccurrencesOfString:suffix withString:@""];
    }

    // Add space before each cap (except the first one)
    if (addSpaces) {
        NSMutableString *spacedString = [NSMutableString string];
        [text enumerateSubstringsInRange:NSMakeRange(0, [text length])
                                options:NSStringEnumerationByComposedCharacterSequences
                            usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
            if ([substring rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet]].location != NSNotFound) {
                return; // ignore spaces
            }
            if (!(substringRange.location == 0 && substringRange.length == 1) && [substring isEqualToString:[substring uppercaseString]]) {
                [spacedString appendString:@" "]; // append space before caps except first character
            }
            [spacedString appendString:substring];
        }];
        return [spacedString copy];
    }
    return text;
}

%hook WFAirportViewController

- (void)viewDidLoad {
    %orig;

    // Add settings tab bar item
    if (@available(iOS 13.0, *)) {
        self.navigationController.visibleViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"gear"] style:UIBarButtonItemStylePlain target:self action:@selector(wfp_openSettings:)];
    } else {
        self.navigationController.visibleViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"WiFiPlus" style:UIBarButtonItemStylePlain target:self action:@selector(wfp_openSettings:)];
    }
}

%new
- (void)wfp_openSettings:(id)sender {
    WFPSettingsViewController *settings = [[WFPSettingsViewController alloc] init];
    settings.presentingVC = self;
    UINavigationController *settingsNav = [[UINavigationController alloc] initWithRootViewController:settings];
    [self presentViewController:settingsNav animated:YES completion:nil];
}

- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion {
    WFPSettingsViewController *toDismissVC;
    if ([self.presentedViewController isKindOfClass:NSClassFromString(@"UINavigationController")]
        && [((UINavigationController *)self.presentedViewController).visibleViewController isKindOfClass:NSClassFromString(@"WFPSettingsViewController")]) {
        toDismissVC = (WFPSettingsViewController *)((UINavigationController *)self.presentedViewController).visibleViewController;
    }
    %orig;
    if (toDismissVC && toDismissVC.needsToPop) {
        [self.navigationController.navigationController popViewControllerAnimated:YES];
    }
}

// Methods crashing on settings updates (might still crash)
- (void)setNetworks:(id)arg1 {
    if (!self.presentedViewController) {
        %orig;
    }
}

- (void)setCurrentNetworkScaledRSSI:(float)arg1 {
    if (!self.presentedViewController) {
        %orig;
    }
}

// Tweak's key methods
- (void)setShowDiagnostics:(BOOL)arg1 {
    %orig([prefs[@"showDiagnostics"] boolValue]);
}

- (BOOL)showDiagnostics {
    return [prefs[@"showDiagnostics"] boolValue];
}

- (void)setShowKnownNetworks:(BOOL)arg1 {
    %orig([prefs[@"showKnownNetworks"] boolValue]);
}

- (BOOL)showKnownNetworks {
    return [prefs[@"showKnownNetworks"] boolValue];
}

%end

%hook WFKnownNetworksViewController

- (void)loadView {
    %orig;
    self.title = localize(kWFLocKnownSectionTitle, @"WiFiKitUILocalizableStrings", PRIVATE_WIFI_BUNDLE);
}

%end

%hook WFKnownNetworkDetailsViewController

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = %orig;
    cell.textLabel.text = autoLocalizedTextForText(cell.textLabel.text, YES);
    cell.detailTextLabel.text = autoLocalizedTextForText(cell.detailTextLabel.text, NO);
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    %orig;

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

%end

%ctor {
    prefs = [NSMutableDictionary dictionaryWithContentsOfFile:PREFS_PATH];
    if (!prefs) prefs = [NSMutableDictionary dictionary];
    if (!prefs[@"showDiagnostics"]) prefs[@"showDiagnostics"] = @YES;
    if (!prefs[@"showKnownNetworks"]) prefs[@"showKnownNetworks"] = @YES;
    if (!prefs[@"autoLocalize"]) prefs[@"autoLocalize"] = @YES;
}
