//
//  JobTableController.m
//  Freelance
//
//  Created by Miquel Camps Ortea on 22/05/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "JobTableController.h"
#import "JobViewController.h"

#import "SVProgressHUD.h"

#include <netinet/in.h>
#import <SystemConfiguration/SCNetworkReachability.h>


@interface JobTableController () <UIAlertViewDelegate>{
    NSMutableArray *arrayC;
    IBOutlet UITableView *tableView;
}

@property (nonatomic, strong) IBOutlet UITableView *tableView;

- (IBAction)info:(id)sender;

@end

@implementation JobTableController

@synthesize tableView;

- (void)viewDidAppear:(BOOL)animated{
    
    [super viewDidAppear:animated];
    
    //TODO: check connection only on request fail, it's not a flight ticket :)
    if ([self connectedToNetwork] ) {
        
        [SVProgressHUD show];
        
        NSString *url = @"http://migueldev.com/freelance/trabajos.php";
        //TODO: should be done asynchronously
        NSData *items = [NSData dataWithContentsOfURL:[NSURL URLWithString:url]];
        NSInputStream *stream = [[NSInputStream alloc] initWithData:items];
        [stream open];
        
        if (stream) {
            
            arrayC = [[NSMutableArray alloc] init];
            
            NSError *parseError = nil;
            id jsonObject = [NSJSONSerialization JSONObjectWithStream:stream options:NSJSONReadingAllowFragments error:&parseError];
            
            NSArray *items = [[jsonObject objectForKey:@"response"] objectForKey:@"jobs"];
            [items enumerateObjectsUsingBlock:^(NSDictionary *item, NSUInteger idx, BOOL *stop) {
                [arrayC addObject:item];
            }];
            
            [self.tableView reloadData]; 
            
        } else {
            NSLog(@"Failed to open stream.");
        }
        
        [SVProgressHUD dismiss];
        
        
    }else{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @"Error" message: @"Hace falta conexión a internet" delegate: self cancelButtonTitle: @"Cancelar" otherButtonTitles: @"Reintentar", nil];
        [alert show];
    }
    
}


- (void)viewDidDisappear:(BOOL)animated{
    
    [super viewDidDisappear:animated];
    [SVProgressHUD dismiss];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}



#pragma mark -
#pragma mark Custom Methods


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"getJob"]) 
    {
        JobViewController *destination = [segue destinationViewController];
        NSIndexPath * indexPath = (NSIndexPath*)sender;
        
        destination.job = [arrayC objectAtIndex:[indexPath row]];
    }
}



- (void)alertView:(UIAlertView *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex != 0){
        [self viewDidAppear:YES];
    }
}

////////////////////////


- (BOOL)connectedToNetwork  {
    // Create zero addy
    struct sockaddr_in zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;
    // Recover reachability flags
    SCNetworkReachabilityRef defaultRouteReachability = SCNetworkReachabilityCreateWithAddress(NULL, (struct sockaddr*)&zeroAddress);
    SCNetworkReachabilityFlags flags;
    BOOL didRetrieveFlags = SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags);
    CFRelease(defaultRouteReachability);
    if (!didRetrieveFlags)
    {
        NSLog(@"Error. Could not recover network reachability flags");
        return 0;
    }
    BOOL isReachable = flags & kSCNetworkFlagsReachable;
    BOOL needsConnection = flags & kSCNetworkFlagsConnectionRequired;
    //below suggested by Ariel
    BOOL nonWiFi = flags & kSCNetworkReachabilityFlagsTransientConnection;
    NSURL *testURL = [NSURL URLWithString:@"http://www.apple.com/"]; //comment by friendlydeveloper: maybe use www.google.com
    NSURLRequest *testRequest = [NSURLRequest requestWithURL:testURL cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:20.0];
    //NSURLConnection *testConnection = [[NSURLConnection alloc] initWithRequest:testRequest delegate:nil]; //suggested by Ariel
    NSURLConnection *testConnection = [[NSURLConnection alloc] initWithRequest:testRequest delegate:nil]; //modified by friendlydeveloper
    return ((isReachable && !needsConnection) || nonWiFi) ? (testConnection ? YES : NO) : NO;
}

////////////////////////


#pragma mark -
#pragma mark IBActions


- (IBAction)info:(id)sender
{
    UIAlertView *someError = [[UIAlertView alloc] initWithTitle: @"Información" message: @"Las ofertas de empleo se dan de alta en http://dir.betabeers.com" delegate: self cancelButtonTitle: @"Ok" otherButtonTitles: nil];
    [someError show];
}


//////////////

#pragma mark -
#pragma mark UITableViewdataSource & UITableViewDelegate


// tabla
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [arrayC count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    static const CGFloat kCellMinHeight = 44.f;
    static const CGFloat kJobTitleLabelFontSize = 20.f;
    static const CGFloat kJobTitleWidth = 300.f;
    static const CGFloat kJobTitleVerticalMargin = 10.f;
    
    NSString *jobTitle = [[arrayC objectAtIndex:indexPath.row] objectForKey:@"title"];
    CGSize size = [jobTitle sizeWithFont:[UIFont systemFontOfSize:kJobTitleLabelFontSize] constrainedToSize:CGSizeMake(kJobTitleWidth, CGFLOAT_MAX)];
    
    return MAX(kCellMinHeight, size.height + kJobTitleVerticalMargin);
}


- (UITableViewCell *)tableView:(UITableView *)tabla cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tabla dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.textLabel.numberOfLines = 0;
    }
    
	NSString *cellValue =[[arrayC objectAtIndex:indexPath.row] objectForKey:@"title"];
	cell.textLabel.text = cellValue ;
    cell.textLabel.font = [UIFont systemFontOfSize:18];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"getJob" sender:indexPath];
}



@end