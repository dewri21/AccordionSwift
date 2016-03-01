//
//  AccordionMenuTableViewController.swift
//  AccordionTableSwift
//
//  Created by Victor Sigler on 2/4/15.
//  Copyright (c) 2015 Private. All rights reserved.
//

import UIKit

class AccordionMenuTableViewController: UITableViewController {
    
    /// The data source for the parent cell.
    var topItems = [String]()
    
    /// The data source for the child cells.
    var subItems = [[String]]()
    
    /// The position for the current items expanded.
    var currentItemsExpanded = [Int]()
    
    /// The originals positions of each parent cell.
    var actualPositions: [Int]!
    
    /// The number of elements in the data source
    var total = 0
    
    /// The identifier for the parent cells.
    let parentCellIdentifier = "ParentCell"
    
    
    /// The identifier for the child cells.
    let childCellIdentifier = "ChildCell"
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setInitialDataSource(numberOfRowParents: 10, numberOfRowChildPerParent: 3)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    /**
     Set the initial data for test the table view.
     
     - parameter parents: The number of parents cells
     - parameter childs:  Then maximun number of child cells per parent.
     */
    private func setInitialDataSource(numberOfRowParents parents: Int, numberOfRowChildPerParent childs: Int) {
        
        // Set the total of cells initially.
        self.total = parents
        
        // Init the array with all the values in -1
        self.actualPositions = [Int](count: parents, repeatedValue: -1)
        
        // Create an array with the element "Item index".
        self.topItems = (0..<parents).enumerate().map { "Item \($0.0 + 1)"}
        
        // Create the array of childs using a random number between 0..childs+1 for each parent.
        self.subItems = (0..<parents).map({ _ -> [String] in
            
            // generate the random number between 0...childs
            let random = Int(arc4random_uniform(UInt32(childs + 1))) + 1
            
            // create the array for each cell
            return (0..<random).enumerate().map {"Subitem \($0.index)"}
        })
    }
    
    /**
     Expand the cell at the index specified.
     
     - parameter index: The index of the cell to expand.
     */
    private func expandItemAtIndex(index : Int) {
        
        // find the parent cell of the cell with index specified.
        let val = self.findParent(index)
        
        // the data of the subitems for the specific parent cell.
        let currentSubItems = self.subItems[val]
        
        // position to start to insert rows.
        var insertPos = index + 1
        
        // create an array of NSIndexPath with the selected positions
        let indexPaths = (0..<currentSubItems.count).map { _ in NSIndexPath(forRow: insertPos++, inSection: 0) }
        
        // insert the new rows
        self.tableView.insertRowsAtIndexPaths(indexPaths, withRowAnimation: UITableViewRowAnimation.Fade)
        
        // update the total of rows
        self.total += self.subItems[val].count
    }
    
    /**
     Collapse the cell at the index specified.
     
     - parameter index: The index of the cell to collapse
     */
    private func collapseSubItemsAtIndex(index : Int) {
        
        var indexPaths = [NSIndexPath]()
        
        // find the parent cell of the cell with index specified.
        let parent = self.findParent(index)
        
        // create an array of NSIndexPath with the selected positions
        for i in index + 1...index + self.subItems[parent].count {
            indexPaths.append(NSIndexPath(forRow: i, inSection: 0))
        }
        
        // remove the expanded cells
        self.tableView.deleteRowsAtIndexPaths(indexPaths, withRowAnimation: UITableViewRowAnimation.Fade)
        
        // update the total of rows
        self.total -= self.subItems[parent].count
    }
    
    /**
     Send the execution to collapse or expand the cell with parent and index specified.
     
     - parameter parent: The parent of the cell.
     - parameter index:  The index of the cell.
     */
    private func setExpandeOrCollapsedStateforCell(parent: Int, index: Int) {
        
        // if the cell is expanded
        if let value = self.currentItemsExpanded.indexOf(parent) {
            
            self.collapseSubItemsAtIndex(index)
            self.actualPositions[parent] = -1
            
            // remove the parent from the expanded list
            self.currentItemsExpanded.removeAtIndex(value)
            
            for i in parent + 1..<self.topItems.count {
                if self.actualPositions[i] != -1 {
                    self.actualPositions[i] -= self.subItems[parent].count
                }
            }
        }
        else {
            
            self.expandItemAtIndex(index)
            self.actualPositions[parent] = index
            
            for i in parent + 1..<self.topItems.count {
                if self.actualPositions[i] != -1 {
                    self.actualPositions[i] += self.subItems[parent].count
                }
            }
            
            // add the parent for the expanded list
            self.currentItemsExpanded.append(parent)
        }
    }
    
    /**
     Check if the cell at indexPath is a child or not.
     
     - parameter indexPath: The NSIndexPath for the cell
     
     - returns: True if it's a child cell, otherwise false.
     */
    private func isChildCell(indexPath: NSIndexPath) -> Bool {
        
        // find the parent cell of the cell with index specified.
        let parent = self.findParent(indexPath.row)
        
        // check if it's expanded or not
        let idx = self.currentItemsExpanded.indexOf(parent)
        
        return idx != nil && indexPath.row != self.actualPositions[parent]
    }
    
    /**
     Find the index of the parent cell for the index of a cell.
     
     - parameter index: The index of the cell to find the parent
     
     - returns: The index of parent cell.
     */
    private func findParent(index : Int) -> Int {
        
        var parent = 0
        var i = 0
        
        while (true) {
            
            if (i >= index) {
                return parent
            }
            
            // if it's expanded the cell
            if let _ = self.currentItemsExpanded.indexOf(parent) {
                
                // sum its childs and continue
                i += self.subItems[parent].count + 1
                
                if (i > index) {
                    return parent
                }
            }
            else {
                i += 1
            }
            parent += 1
        }
    }
}

extension AccordionMenuTableViewController {
    
    // MARK: UITableViewDataSource
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.total
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell : UITableViewCell!
        let parent = self.findParent(indexPath.row)

        if self.isChildCell(indexPath) {
            cell = tableView.dequeueReusableCellWithIdentifier(childCellIdentifier, forIndexPath: indexPath)
            cell.textLabel!.text = self.subItems[parent][indexPath.row - self.actualPositions[parent] - 1]
            cell.backgroundColor = UIColor.greenColor()
        }
        else {
            cell = tableView.dequeueReusableCellWithIdentifier(parentCellIdentifier, forIndexPath: indexPath)
            cell.textLabel!.text = self.topItems[parent]
        }
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        guard !self.isChildCell(indexPath) else {
            NSLog("A child was tapped!!!");
            return
        }
        
        self.tableView.beginUpdates()
        
        let parent = self.findParent(indexPath.row)
        self.setExpandeOrCollapsedStateforCell(parent, index: indexPath.row)
        
        self.tableView.endUpdates()
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return self.isChildCell(indexPath) ? 44.0 : 64.0
    }
}