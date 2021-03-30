//
//  CollectionViewController.swift
//  Gallery
//
//  Created by Divyesh Vekariya on 20/03/21.
//

import UIKit
import CoreData


private let reuseIdentifier = "Cell"
private let reloadCellReuseIdentifier = "ReloadCell"
private let reuseViewIdentifier = "SectionHeader"

class CollectionViewController: UICollectionViewController {
    @IBOutlet weak var leftBarItem: UIBarButtonItem!
    @IBOutlet weak var rightBarItem: UIBarButtonItem!
    var myUsers = [[User](), [User]()]
    var isCollectionEditing = false
    var selectedItems = [IndexPath]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressGesture))
        collectionView?.addGestureRecognizer(gesture)
        collectionView.reloadData()
       //deleteAllRecords()
        for index in 0..<myUsers.count{
            myUsers[index].append(contentsOf: fetchData(section: index))
            refreshBarButton()

        }
    }
    
    @objc func handleLongPressGesture(_ gesture: UILongPressGestureRecognizer){
        guard let collectionView = collectionView else {
            return
        }
        switch gesture.state {
        case .began:
            guard let  targetIndexPath = collectionView.indexPathForItem(at: gesture.location(in: collectionView)) else {
                return
            }
            collectionView.beginInteractiveMovementForItem(at: targetIndexPath)
        case .changed:
            collectionView.updateInteractiveMovementTargetPosition(gesture.location(in: collectionView))
        case .ended:
            collectionView.endInteractiveMovement()
        default:
            collectionView.cancelInteractiveMovement()
        }
     }
    
    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return myUsers.count
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if myUsers[section].count == 0 {
            return 1
        } else {
            return myUsers[section].count+1
        }
}

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.row == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reloadCellReuseIdentifier, for: indexPath) as! ReloadCollectionViewCell
            cell.reloadButton.tag = indexPath.section
            cell.activityIndicator.isHidden = true
            cell.reloadButton.isHidden = false
            cell.buttonTapCallback = { [weak self, weak collectionView] sender in
                guard let this = self else {
                    return
                }
                cell.activityIndicator.isHidden = false
                cell.reloadButton.isHidden = true
                cell.activityIndicator.startAnimating()
                //                cell.reloadButton.imageView?.isHidden = true  // hide pluse symbole
                //                //cell.reloadButton.isEnabled = false           //disable reload button
                print((sender as! UIButton).tag)
                print("Button taped \(indexPath.section)")
                // collectionView?.deleteItems(at: [indexPath])
                this.downloadJson (section: (indexPath.section)){ users  in
                    this.saveUserData(users, section: (indexPath.section))
                    let users = this.fetchData(section:(indexPath.section))
                    this.myUsers[indexPath.section].append(contentsOf: users)
                    collectionView?.reloadData()
                    cell.activityIndicator.stopAnimating()
                    cell.activityIndicator.isHidden = true
                    cell.reloadButton.isHidden = false
                } errorblock: { (Error) in
                    print("error\(Error)")
                }
                
                
            }
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! CollectionViewCell
            if myUsers[indexPath.section].count != 0 {
                cell.selectionIndecatorImageView.isHidden = !isCollectionEditing
                cell.selectionIndecatorImageView.isHighlighted = selectedItems.contains(indexPath)
                cell.imageView.downloaded(from: myUsers[indexPath.section][indexPath.item-1].avatar_url)
                return cell
            } else{
                return cell
            }
        }
        
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize(width: collectionView.frame.size.width/3.2, height: collectionView.frame.size.width/3.2)
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {

        if let sectionHeader = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: reuseViewIdentifier, for: indexPath) as? CollectionReusableView{
            sectionHeader.sectionHeaderNameLable.text = "Section - \(indexPath.section)"
            return sectionHeader
        }
        return UICollectionReusableView()
    }
    override func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        return indexPath.item != 0
    }
    override func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let item = myUsers[sourceIndexPath.section].remove(at: sourceIndexPath.item-1)
        myUsers[destinationIndexPath.section].insert(item, at: destinationIndexPath.item-1)
    }
    

    // MARK: UICollectionViewDelegate
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if isCollectionEditing {
            if let index = selectedItems.firstIndex(of: indexPath) {
                selectedItems.remove(at: index)
            } else{
                selectedItems.append(indexPath)
            }
            collectionView.reloadItems(at: [indexPath])
        }

    }
    //MARL: Downloading JSON
    func downloadJson(section: Int, completed: @escaping ([User]) -> (), errorblock: @escaping ( (Error) -> () )) {
        var urlCom = URLComponents(string: "https://api.github.com/users")
        
        var queryItem = [URLQueryItem]()
        if let lastUser = myUsers[section].last {
            queryItem.append(.init(name: "since", value: String(lastUser.id)))
        }
        queryItem.append(.init(name: "per_page", value: String(10)))
        urlCom?.queryItems = queryItem
        
        guard let url = urlCom?.url else {
            print("Found nil url")
            return
        }
        
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let error = error {
                DispatchQueue.main.async{
                    errorblock(error)
                }
            } else {
                do {
                    let users = try JSONDecoder().decode([User].self, from: data!)
                    DispatchQueue.main.async{
                        completed(users)
                    }
                } catch let error {
                    print("JSON Error")
                    DispatchQueue.main.async{
                        errorblock(error)
                    }
                }
                
            }
            
        }.resume()
    }
    
    //MARK: CoreData
    //create or save data
    func saveUserData(_ users: [User], section: Int) {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        for user in users {
            do {
                let newUser = NSEntityDescription.insertNewObject(forEntityName: "Person", into: context)
                newUser.setValue(section, forKey: "section")
                newUser.setValue(user.id, forKey: "idtag")
                newUser.setValue(user.avatar_url, forKey: "imagelink")
                newUser.setValue(user.login, forKey: "username")
                try context.save()
                print("Success")
            } catch {
                print("Error saving: \(error)")
            }
        }
    }
    //Fatch core data
    func fetchData( section: Int) -> [User]{
        
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Person")
        fetchRequest.predicate = NSPredicate(format: "section == %d", section)
        
        do {
            let result = try context.fetch(fetchRequest) as! [NSManagedObject]
            var users = [User]()
            for item in result {
                let section = item.value(forKey: "section") as! Int
                let idtag = item.value(forKey: "idtag") as! Int
                let imagePath = item.value(forKey: "imagelink") as! String
                let username = item.value(forKey: "username") as! String
                users.append(User(login: username,id: idtag, avatar_url: imagePath, section: section))
            }
            return users
        }catch let err as NSError {
            print(err.debugDescription)
            return []
        }
    }
    
    //Update core data
    //Delete from core data
    func deleteAllRecords() {
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let context = delegate.persistentContainer.viewContext
        
        let deleteFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Person")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: deleteFetch)
        
        do {
            try context.execute(deleteRequest)
            try context.save()
        } catch {
            print ("There was an error")
        }
    }
    
    func deletUsers(_ deleteList:[User]) {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Person")
        
        let predicates = deleteList.map({ NSPredicate(format: "idtag == %d AND section == %d", $0.id, $0.section! ) })
        
//        let idtagPredicate = NSPredicate(format: "idtag == %d AND section == %d", )
        
//        let sectionPredicate = NSPredicate(format: "section IN %d", deleteList.compactMap({ $0.section }))
        
        fetchRequest.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
        
        do {
            let objects = try context.fetch(fetchRequest) as! [NSManagedObject]
            for object in objects {
                context.delete(object)
            }
            try context.save()
        } catch _ {
            // error handling
        }
    }
    
    @IBAction func onLefitemClick(_ sender: Any) {
        isCollectionEditing.toggle()
        collectionView.reloadData()
        selectedItems.removeAll()
        refreshBarButton()
    }
    @IBAction func onRightItemClick(_ sender: Any) {
        let usersToDelete = selectedItems.map({ myUsers[$0.section][$0.item-1] })
        
        for user in usersToDelete where user.section != nil {
            myUsers[user.section!].removeAll(where: { $0.id == user.id })
        }
        
        deletUsers(usersToDelete)
        collectionView.performBatchUpdates {
            collectionView.deleteItems(at: selectedItems)
        } completion: { _ in
            self.isCollectionEditing = false
            self.refreshBarButton()
            self.collectionView.reloadData()
        }
        selectedItems.removeAll()
    }
    
    func refreshBarButton() {
        if isCollectionEditing == true {
            leftBarItem.title = "Done"
            rightBarItem.isEnabled = true
        } else{
            leftBarItem.title = "Edit"
            rightBarItem.isEnabled = false
        }
    }
    
}

extension UIImageView {
    static var cache = [URL: UIImage]()
    
    func downloaded(from url: URL, contentMode mode: UIView.ContentMode = .scaleAspectFit) {
        contentMode = mode
        if let image = Self.cache[url]{
            self.image = image
            return
        }
        URLSession.shared.dataTask(with: url) { [url] data, response, error in
            guard
                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data, error == nil,
                let image = UIImage(data: data)
            else { return }
            DispatchQueue.main.async() { [weak self] in
                self?.image = image
                Self.cache[url] = image
            }
        }.resume()
    }
    func downloaded(from link: String, contentMode mode: UIView.ContentMode = .scaleAspectFit) {
        guard let url = URL(string: link) else { return }
        downloaded(from: url, contentMode: mode)
    }
}

extension CollectionViewController : UICollectionViewDelegateFlowLayout {
    
}


