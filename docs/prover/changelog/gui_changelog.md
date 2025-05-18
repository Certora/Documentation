GUI Release Notes
=============

```{contents}
```

5.0.1 (May 18, 2025)
---------------------------

### Features

- [feat] Rule Report - Nesting In Variables Tab: Enhance the Variables tab by introducing aggregation functionality to `env` and method variables. This will simplify scrolling, navigation, and comprehension for users by mirroring the aggregation behavior in the Call Trace for complex storage types (`env` variables and method parameters).

### Fixed Bugs

- [bug] Rule Report - Fixed wrong time presented in the Rule Report based on local time
- [bug] Rule Report - Add missing tooltips for collapse/expand buttons, and improved max-width to rule name tooltips

4.3.0 (Apr 10, 2025)
---------------------------

### Features

- [feat] Rule Report - Navigating to report with completed state, will now mark this job as “opened” in the Dashboard job list.
- [feat] Rule Report - State-Diff: introducing the option to compare the state of the storage between different snapshots within the call trace. This option will aid users in understanding counter examples and debugging problems.
- [feat] Rule Report - Full-screen Notifications Tab: Added a new full-screen (expanded) tab state to the notification panel for improved readability and navigation. Users can now easily switch between collapsed, small, and full-screen views to better manage long notifications.
- [feat] Dashboard - Jobs list will now highlight unopened jobs. Jobs will be marked as “opened” by opening a report in a completed state, or by marking this manually in the dashboard.
- [feat] Dashboard - Job list will now present the run_source of a job and enable filtering by run_source

### Fixed Bugs

- [bug] Rule Report - Log out from Rule Report is now working as expected
- [bug] Dashboard - Canceling a job from the Dashboard is now working as expected

4.0.2 (Mar 13, 2025)
---------------------------

### Features

- [feat] Rule Report - Added icons and highlighter for Solana reports. 
- [feat] Rule Report - Improved Call Trace and Variables readability by truncating long values
- [feat] Dashboard - Added tooltips for column headers

4.0.0 (Feb 19, 2025)
---------------------------

### Features

- [feat] Rule Report - Improved call trace filtering & navigation, to provide more flexibility and ease of use. You can now toggle between search and filter modes. Additionally, you can navigate results via the up/down arrows, similar to CTRL+F in a browser, to move through matches efficiently. 
- [feat] Rule Report - Added click-to-copy variables in call trace and variables tab

3.1.1 (Jan 12, 2025)
---------------------------

### Features

- [feat] Support for displaying numeric values in string, decimal, or hexadecimal formats in Call Trace and Variables tabs, with a dropdown to switch formats.
- [feat] Persist column configuration (display selection and width) across browser sessions on the Prover Dashboard, including between tabs and logins.
- [feat] Added call traces and TAC dumps for sanity rules in Rule Report.


3.0.2 (Nov 18, 2024)
---------------------------

### Features

- [feat] Improved formatting of the call trace: The call trace highlights values of the counter examples as gray boxes and provides tooltips indicating the semantics of the value (e.g. if the value is a return value or a parameter of a function call).
- [feat] The rule tree automatically opens a node if it only contains a single child element. This reduces the number of user interactions required to get to the call trace and find the counter example.


2.4.4 (Nov 6, 2024)
---------------------------

### Features

- [feat] Adding support for syntax highlighting of Rust files in the code editor
- [feat] Flags in the config tab link to the flags in the documentation.

### Fixed Bugs

- [bug] The re-run button was reported to not function for non-Certora users. This has been fixed.


2.4.1 (Oct 6, 2024)
---------------------------

### Features

- [feat] Rule progress indicator: The progress of individual rules will be displayed in the tree view. Each node in the rule tree shows how many children have been completed already.
- [feat] Re-run feature is available to all users. Upon a timeout of a rule, the user is able to re-run the particular rule with a portfolio of configurations aiming to solve the timeout.


2.3.2 (Sep 2, 2024)
---------------------------

### Features

- [feat] Global Notifications New UI


2.2.0 (Jul 24, 2024)
---------------------------

### Features

- [feat] Job execution status in browser tab


2.1.6 (Jul 8, 2024)
---------------------------

### Features

- [bugfix] Call trace performance improvements
- [feat] Re-run feature: A rule that timed out can be re-submitted as individual job (experimental, for selected users only)
- [feat] Allow the user to logout from rule report

  
2.0.1 (May 15, 2024)
---------------------------

### Features

- [feat] Support for jump to source from variables tab
- [feat] Support for jump to source from live statistics tab
- [feat] Allow the call trace to be expanded to full screen

### Fixed Bugs

- [fix] Expansion bug on the main UI grid
- [fix] Fixes for the call trace tracking points


1.0.0 (Apr 11, 2024)
---------------------------

### Features

- [feat] Jump To Source: Animation to highlight already selected line on button click
- [feat] New Job Configuration Tab that provides details on all arguments and inputs of a job that has been executed with (main contract, solidity version, all Prover flags and CLI options)
- [feat] Browser tab title now indicates the main contract and the message of the job to simplify identification of a job
- [feat] Files with extension `.yul` - [Yul files](https://docs.soliditylang.org/en/latest/yul.html) - can be displayed in the editor

### Fixed Bugs

- [fix] When a job has been canceled or halted, only rules that were running are being displayed as killed 

  
0.8.0 (Mar 11, 2024)
---------------------------

### Features

- [feat] Jump To Source Feature (works only in combination with Certora version later than 7.1.0)
- [feat] New tooltips on labels for the call trace

### Fixed Bugs

- [fix] Fixed tracking points
- [fix] Fixed sharing button


0.7.0 (Feb 12, 2024)
---------------------------

### Fixed Bugs

- [fix] Fixed bug when collapsing the left pane of the main grid
- [fix] Fixed bug when collapsing entries in the call trace


0.6.0 (Jan 31, 2024)
---------------------------

### Features

- [feat] Live Difficulty Statistics
- [feat] Adding tool tips to status

### Fixed Bugs

- [fix] Fixed file contents were shown to be loading for indefinite time


0.5.7 (Nov 26, 2023)
---------------------------

### Features

- [feat] Improvements on naming for global / rule notifications


0.5.62 (Feb 11, 2024)
---------------------------

### Fixed Bugs

- [fix] Fixed removed links to deprecated Certora Forum


0.5.6 (October 24, 2023)
---------------------------

### Features

- [feat] Shareable report button
- [feat] Foldable call trace
- [feat] Added view of `.conf` files in the source files tab
- [feat] New Tracking Points feature in the call trace
- [feat] Added support for Witness examples view
- [feat] Added link to the unsat core page inside info tab
- [feat] Added job status at the top level
- [feat] Default first load of the report shows the spec file and rules tab only
- [feat] Display the report version in the info tab
- [feat] Added a floating column option for the main sidebar
- [feat] Added animated icons for jobs status in progress
- [feat] Files tab keeps expanded files state
- [feat] Improved filter, filter highlight, and search highlight functionality inside call resolutions
- [feat] Added code editor scroll position to state
- [feat] Added columns width to local storage
- [feat] Removed cancel job button from the report
- [feat] Removed auto-scroll in call Trace
- [feat] Improved drop filters
- [feat] Improved component's state handling
- [feat] Added upload failed view


### Fixed Bugs

- [bugfix] Fixed the issue of selected file not being shown in the file tree
- [bugfix] Fixed call resolution empty state issue
- [bugfix] Fixed global problems empty state issue
- [bugfix] Support for view of files with same name in different folders
- [bugfix] Support file opening twice
- [bugfix] Fixed handling collapse functionality when data is filtered
- [bugfix] Fixed Firefox warnings on the source files tab
- [bugfix] Fixed filter and collapse on contracts and global call resolution tabs to be consistent
- [bugfix] Fixed contracts tab to show more/less and line breaks
- [bugfix] Fixed UI breaking when selecting a new rule
- [bugfix] Fixed issue of multi counter example shown without call trace
- [bugfix] Fixed call resolution opening two items by default instead of one
- [bugfix] Fixed view of job run time to excluded the time the job waited in the queue
- [bugfix] Fixed variables sorting order

