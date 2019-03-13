# Whats different on this fork:
- Easy integration, the table view can be added and configured using interface builder.
- Easy configuration, the arrow image, background color and text color can simply be changed by properties of the PullTableView class.
- *Pull to reload more data* functionality at the bottom of the table.
- Possibility to trigger the *refreshing* and *loading more* animations by code.

# The fast setup:
- Add QuartzCore.framework to your project
- Drag drop EGOTableViewPullRefresh directory to your project.
- Look at the PullTableView.h file for available properties.
- Add a PullTableView to your code and implement the PullTableViewDelegate methods.
- Enjoy!

# The detailed setup (Walk through for creating the demo project):
- Create a new Xcode project
- Choose *View Based Application*
- Product name: EGOTableViewPullRefreshDemo
- Create it in desired folder
- Add *QuartzCore.framework* to the project

**Adding the PullTableView to the project:**

- Drag drop EGOTableViewPullRefresh directory to the Supporting Files group in the project, make sure items are copied into destination groups folder.

**Adding the PullTable to the view `EGOTableViewPullRefreshDemoViewController.xib`:**

- Drag drop a UITableView to the view.
- Open the *Identity inspector* and change the Class from 'UITableView' to PullTableView
- Connect the dataSource and pullDelegate outlets of the PullTableView to File's owner

**Configuring view controller Header `EGOTableViewPullRefreshDemoViewController.h`:**

- Add `#import "PullTableView.h"`
- Make it conform to PullTableViewDelegate and UITableViewDataSource
- Create an outlet property named pullTableView and connect it to the table in interface builder.

**Configuring view controller Footer `EGOTableViewPullRefreshDemoViewController.m`**

- Add the following code to the m file.

        #pragma mark - Refresh and load more methods
        
        - (void) refreshTable
        {
            /*
             
                 Code to actually refresh goes here.
             
             */
            self.pullTableView.pullLastRefreshDate = [NSDate date];
            self.pullTableView.pullTableIsRefreshing = NO;
        }
        
        - (void) loadMoreDataToTable
        {
            /*
             
             Code to actually load more data goes here.
             
             */
            self.pullTableView.pullTableIsLoadingMore = NO;
        }
        
        #pragma mark - UITableViewDataSource
        
        - (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
        {
            return 5;
        }
        
        - (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
        {
            return 10;
        }
        
        - (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
        {
            static NSString *cellIdentifier = @"Cell";
            
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
            
            if(!cell) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
            }
            cell.textLabel.text = [NSString stringWithFormat:@"Row %i", indexPath.row];
            
            return cell;
        }
        
        - (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
        {
            return [NSString stringWithFormat:@"Section %i begins here!", section];
        }
        
        - (NSString *) tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
        {
            return [NSString stringWithFormat:@"Section %i ends here!", section];
        }
        
        #pragma mark - PullTableViewDelegate
        
        - (void)pullTableViewDidTriggerRefresh:(PullTableView *)pullTableView
        {
    
            [self performSelector:@selector(refreshTable) withObject:nil afterDelay:3.0f];
        }
        
        - (void)pullTableViewDidTriggerLoadMore:(PullTableView *)pullTableView
        {
            [self performSelector:@selector(loadMoreDataToTable) withObject:nil afterDelay:3.0f];
        }
    
    
- For UI configuration add the following code inside viewDidLoad

        self.pullTableView.pullArrowImage = [UIImage imageNamed:@"blackArrow"];
        self.pullTableView.pullBackgroundColor = [UIColor yellowColor];
        self.pullTableView.pullTextColor = [UIColor blackColor];

- For manually triggering animation use the pullTableIsRefreshing and pullTableIsLoadingMore properties. For example add the following code to viewWillAppear:

        if(!self.pullTableView.pullTableIsRefreshing) {
            self.pullTableView.pullTableIsRefreshing = YES;
            [self performSelector:@selector(refreshTable) withObject:nil afterDelay:3];
        }