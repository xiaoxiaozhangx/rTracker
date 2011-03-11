//
//  configTlistController.m
//  rTracker
//
//  Created by Robert Miller on 06/05/2010.
//  Copyright 2010 Robert T. Miller. All rights reserved.
//

#import "configTlistController.h"
#import "trackerList.h"
#import "addTrackerController.h"


@implementation configTlistController

@synthesize tlist;
@synthesize table;

static int selSegNdx=SegmentEdit;

NSIndexPath *deleteIndexPath; // remember row to delete if user confirms in checkTrackerDelete alert
UITableView *deleteTableView;

#pragma mark -
#pragma mark core object methods and support

- (void)dealloc {
	NSLog(@"configTlistController dealloc");
	self.tlist = nil;
	[tlist release];
	 
	self.table = nil;
	[table release];
	
    [super dealloc];
}


# pragma mark -
# pragma mark view support

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	
	self.title = @"configure trackers";

	UIBarButtonItem *exportBtn = [[UIBarButtonItem alloc]
								  initWithTitle:@"export"
								  style:UIBarButtonItemStyleBordered
								  target:self
								  action:@selector(btnExport)];
	
	NSArray *tbArray = [NSArray arrayWithObjects: exportBtn, nil];
	
	self.toolbarItems = tbArray;
	[exportBtn release];
	
	
	[super viewDidLoad];
}


- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	
	NSLog(@"configTlistController view didunload");
	
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;

	self.title = nil;
	self.tlist = nil;
	self.table = nil;
	self.toolbarItems = nil;

	[super viewDidLoad];
	
}

- (void)viewWillAppear:(BOOL)animated {
	
	NSLog(@"ctlc: viewWillAppear");
	
	[self.table reloadData];
	selSegNdx=SegmentEdit;  // because mode select starts with default 'modify' selected
	
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
	NSLog(@"ctlc: viewWillDisappear");

	//self.tlist = nil;
	
	[super viewWillDisappear:animated];
}

#pragma mark -
#pragma mark button press action methods

- (NSString *) ioFilePath:(NSString*)fname {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);  // file itunes accessible
	//NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);  // files not accessible
	NSString *docsDir = [paths objectAtIndex:0];
	
	NSLog(@"ioFilePath= %@",[docsDir stringByAppendingPathComponent:fname] );
	
	return [docsDir stringByAppendingPathComponent:fname];
}

- (IBAction)btnExport {
	NSLog(@"btnExport was pressed!");

	NSString *fpath = [self ioFilePath:@"rTracker_out.xls"];
	[[NSFileManager defaultManager] createFileAtPath:fpath contents:nil attributes:nil];
	NSFileHandle *nsfh = [NSFileHandle fileHandleForWritingAtPath:fpath];
	
	[nsfh writeData:[@"hello, world." dataUsingEncoding:NSUTF8StringEncoding]];
	 
	[self.tlist writeTListXLS:nsfh];
	[nsfh closeFile];
	//[nsfh release];
}

- (IBAction) modeChoice:(id)sender {

	switch (selSegNdx = [sender selectedSegmentIndex]) {
		case SegmentEdit :
			NSLog(@"ctlc: set edit mode");
			[self.table setEditing:NO animated:YES];
			break;
		case SegmentCopy :
			NSLog(@"ctlc: set copy mode");
			[self.table setEditing:NO animated:YES];
			break;
		case SegmentMoveDelete :
			NSLog(@"ctlc: set move/delete mode");
			[self.table setEditing:YES animated:YES];
			break;
		default:
			NSAssert(0,@"ctlc: segment index not handled");
			break;
	}
			
			
}

#pragma mark -
#pragma mark UIActionSheet methods

- (void) delTracker
{
	NSUInteger row = [deleteIndexPath row];
	NSLog(@"checkTrackerDelete: will delete row %d ",row);
	[self.tlist deleteTrackerAllRow:row];
	[deleteTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:deleteIndexPath] 
						   withRowAnimation:UITableViewRowAnimationFade];		
	[self.tlist reloadFromTLT];	
}


- (void)actionSheet:(UIActionSheet *)checkTrackerDelete clickedButtonAtIndex:(NSInteger)buttonIndex 
{
	NSLog(@"checkTrackerDelete buttonIndex= %d",buttonIndex);
	
	if (buttonIndex == checkTrackerDelete.destructiveButtonIndex) {
		[self delTracker];
	} else {
		NSLog(@"cancelled");
	}
	
}
					 
					 
#pragma mark -
#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [self.tlist.topLayoutNames count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView 
		 cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"rvc table cell at index %d label %@",[indexPath row],[self.tlist.topLayoutNames objectAtIndex:[indexPath row]]);
	
    static NSString *CellIdentifier;
	
	if (selSegNdx == SegmentMoveDelete) {
		CellIdentifier = @"DeleteCell";
	} else {
		CellIdentifier = @"Cell";
	}
		
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
	// Configure the cell.
	NSUInteger row = [indexPath row];
	cell.textLabel.text = [self.tlist.topLayoutNames objectAtIndex:row];
	
    return cell;
}

- (BOOL)tableView:(UITableView *)tableview canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *) fromIndexPath 
	  toIndexPath:(NSIndexPath *) toIndexPath {
	NSUInteger fromRow = [fromIndexPath row];
	NSUInteger toRow = [toIndexPath row];
	
	NSLog(@"ctlc: move row from %d to %d",fromRow, toRow);
	[self.tlist reorderTLT :fromRow toRow:toRow];
	[self.tlist reorderFromTLT];
	
}
					 
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle 
forRowAtIndexPath:(NSIndexPath *)indexPath {
	deleteIndexPath = indexPath;
	deleteTableView = tableView;
	
	int toid = [self.tlist getTIDfromIndex:[indexPath row]];
	trackerObj *to = [[trackerObj alloc] init:toid];
	BOOL haveData = [to checkData];
	[to release];
	
	if (haveData) {
		UIActionSheet *checkTrackerDelete = [[UIActionSheet alloc] 
											 initWithTitle:[NSString stringWithFormat:
															@"Really delete all data for %@?",
															[self.tlist.topLayoutNames objectAtIndex:[indexPath row]]]
											 delegate:self 
											 cancelButtonTitle:@"Cancel"
											 destructiveButtonTitle:@"Yes, delete"
											 otherButtonTitles:nil];
		//[checkTrackerDelete showInView:self.view];
		[checkTrackerDelete showFromToolbar:self.navigationController.toolbar ];
		[checkTrackerDelete release];
	} else {
		[self delTracker];
	}
}

// Override to support row selection in the table view.
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	
    // Navigation logic may go here -- for example, create and push another view controller.
	// AnotherViewController *anotherViewController = [[AnotherViewController alloc] initWithNibName:@"AnotherView" bundle:nil];
	// [self.navigationController pushViewController:anotherViewController animated:YES];
	// [anotherViewController release];
	
	NSUInteger row = [indexPath row];
	NSLog(@"configTList selected row %d : %@", row, [self.tlist.topLayoutNames objectAtIndex:row]);
	
	if (selSegNdx == SegmentEdit) {
		int toid = [self.tlist getTIDfromIndex:row];
		NSLog(@"will config toid %d",toid);
		
		addTrackerController *atc = [[addTrackerController alloc] initWithNibName:@"addTrackerController" bundle:nil ];
		atc.tlist = self.tlist;
		atc.tempTrackerObj = [[trackerObj alloc] init:toid];
	
		[self.navigationController pushViewController:atc animated:YES];
		[atc release];
	} else if (selSegNdx == SegmentCopy) {
		int toid = [self.tlist getTIDfromIndex:row];
		NSLog(@"will copy toid %d",toid);

		trackerObj *oTO = [[trackerObj alloc] init:toid];
		trackerObj *nTO = [self.tlist toConfigCopy:oTO];
		[self.tlist confirmTopLayoutEntry:nTO];
		[oTO release];
		[nTO release];
		[self.tlist loadTopLayoutTable];
		[self.table reloadData];

	} else if (selSegNdx == SegmentMoveDelete) {
		NSLog(@"selected for move/delete?");
	}
}
@end