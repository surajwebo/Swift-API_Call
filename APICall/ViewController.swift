//
//  ViewController.swift
//  APICall
//
//  Created by Suraj on 20/02/15.
//  Copyright (c) 2015 Suraj. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    var tableData = []
    var imageCache = [String : UIImage]()
    @IBOutlet weak var tableViewSearchedItems: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        searchItunesFor(searchBar.text)
        searchBar.resignFirstResponder()
    }
    
    func searchItunesFor(searchTerm: String) {
        // The iTunes API wants multiple terms separated by + symbols, so replace spaces with + signs
        let itunesSearchTerm = searchTerm.stringByReplacingOccurrencesOfString(" ", withString: "+", options: NSStringCompareOptions.CaseInsensitiveSearch, range: nil)
        
        // Now escape anything else that isn't URL friendly
        if let escapedSearchTerm = itunesSearchTerm.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding) {
            let urlPath = "http://itunes.apple.com/search?term=\(escapedSearchTerm)&media=software"
            let url = NSURL(string: urlPath)
            let session = NSURLSession.sharedSession()
            let task = session.dataTaskWithURL(url!, completionHandler: {data, response, error -> Void in
                println("Task completed")
                if(error != nil) {
                    // If there is an error in the web request, print it to the console
                    println(error.localizedDescription)
                }
                var err: NSError?
                
                var jsonResult = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: &err) as NSDictionary
                if(err != nil) {
                    // If there is an error parsing JSON, print it to the console
                    println("JSON Error \(err!.localizedDescription)")
                }
                let results: NSArray = jsonResult["results"] as NSArray
                dispatch_async(dispatch_get_main_queue(), {
                    self.tableData = results
                    self.tableViewSearchedItems!.reloadData()
                })
            })
            
            task.resume()
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCellWithIdentifier("SearchedResultCellID") as? UITableViewCell {
            let rowData: NSDictionary = self.tableData[indexPath.row] as NSDictionary
            
            var lblTitle : UILabel = cell.contentView.viewWithTag(1) as UILabel;
            lblTitle.text = rowData["trackName"] as? String
            
            var lblDescription : UILabel = cell.contentView.viewWithTag(2) as UILabel
            lblDescription.text = rowData["formattedPrice"] as NSString
            
            var imgViewLogo : UIImageView = cell.contentView.viewWithTag(3) as UIImageView
            let urlString: NSString = rowData["artworkUrl60"] as NSString
            
            /* // Synchronous Downloading Images from URL
            let imgURL: NSURL? = NSURL(string: urlString)
            let imgData = NSData(contentsOfURL: imgURL!)
            
            imgViewLogo.image = UIImage(data: imgData!)*/
            
            // Asynchronous Downloading Images from URL
            var image = self.imageCache[urlString]
            if(image == nil) {
                // If the image does not exist, we need to download it
                var imgURL: NSURL = NSURL(string: urlString)!
                
                // Download an NSData representation of the image at the URL
                let request: NSURLRequest = NSURLRequest(URL: imgURL)
                NSURLConnection.sendAsynchronousRequest(request, queue: NSOperationQueue.mainQueue(), completionHandler: {(response: NSURLResponse!,data: NSData!,error: NSError!) -> Void in
                    if error == nil {
                        image = UIImage(data: data)
                        
                        // Store the image in to our cache
                        self.imageCache[urlString] = image
                        dispatch_async(dispatch_get_main_queue(), {
                            if let cellToUpdate = tableView.cellForRowAtIndexPath(indexPath) {
                                imgViewLogo.image = image
                            }
                        })
                    }
                    else {
                        println("Error: \(error.localizedDescription)")
                    }
                })
                
            }
            else {
                dispatch_async(dispatch_get_main_queue(), {
                    if let cellToUpdate = tableView.cellForRowAtIndexPath(indexPath) {
                        imgViewLogo.image = image
                    }
                })
            }
            
            return cell
        } else {
            NSLog("Prototype did not work")
            let cell: UITableViewCell = UITableViewCell(style: UITableViewCellStyle.Subtitle, reuseIdentifier: "Cell")
            cell.textLabel.text = "Search results not found"
            return cell
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 90.0
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "iTunes"
    }
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 1
    }
    
    func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        println("Selected Section: \(indexPath.section) Row: \(indexPath.row)")
    }
}