/*
* Copyright (c) 2015 Razeware LLC
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
* THE SOFTWARE.
*/

import UIKit
import CoreData

class NotesListViewController: UITableViewController, NSFetchedResultsControllerDelegate {
  lazy var stack : CoreDataStack = CoreDataStack(modelName:"UnCloudNotesDataModel", storeName:"UnCloudNotes",
                                                 options: [
													NSMigratePersistentStoresAutomaticallyOption: true,
													NSInferMappingModelAutomaticallyOption: true ])
  
  lazy var notes : NSFetchedResultsController = {
    let request = NSFetchRequest(entityName: "Note")
    request.sortDescriptors = [NSSortDescriptor(key: "dateCreated", ascending: false)]
    
    let notes = NSFetchedResultsController(fetchRequest: request, managedObjectContext: self.stack.context, sectionNameKeyPath: nil, cacheName: nil)
    notes.delegate = self
    return notes
  }()
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    do {
      try notes.performFetch()
    } catch let error as NSError {
      print("Error fetching data \(error)")
    }
    tableView.reloadData()
  }
  
  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    let objects = notes.fetchedObjects
    return objects?.count ?? 0
  }
  
  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    if let cell = tableView.dequeueReusableCellWithIdentifier("NoteCell", forIndexPath: indexPath) as? NoteTableViewCell {
      if let objects = notes.fetchedObjects {
        cell.note = objects[indexPath.row] as? Note
      }
      return cell
    }
    return UITableViewCell()
  }
  
  func controllerWillChangeContent(controller: NSFetchedResultsController) {
  }
  
  func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
    let indexPathsFromOptionals: (NSIndexPath?) -> [NSIndexPath] = { indexPath in
      if let indexPath = indexPath {
        return [indexPath]
      }
      return []
    }
    
    switch type {
    case .Insert:
      tableView.insertRowsAtIndexPaths(indexPathsFromOptionals(newIndexPath), withRowAnimation: .Automatic)
    case .Delete:
      tableView.deleteRowsAtIndexPaths(indexPathsFromOptionals(indexPath), withRowAnimation: .Automatic)
    default:
      break
    }
  }
  
  func controllerDidChangeContent(controller: NSFetchedResultsController) {
  }
  
  @IBAction
  func unwindToNotesList(segue:UIStoryboardSegue) {
    NSLog("Unwinding to Notes List")
    
    if stack.context.hasChanges {
      do {
        try stack.context.save()
      } catch let error as NSError {
        print("Error saving context: \(error)")
      }
    }
  }
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "createNote" {
      let context = NSManagedObjectContext(concurrencyType: .PrivateQueueConcurrencyType)
      context.parentContext = stack.context
      if let navController = segue.destinationViewController as? UINavigationController {
        if let nextViewController = navController.topViewController as? CreateNoteViewController {
          nextViewController.managedObjectContext = context
        }
      }
    }
    if segue.identifier == "showNoteDetail" {
      if let detailView = segue.destinationViewController as? NoteDetailViewController {
        if let selectedIndex = tableView.indexPathForSelectedRow {
          if let objects = notes.fetchedObjects {
            detailView.note = objects[selectedIndex.row] as? Note
          }
        }
      }
    }
  }
}
