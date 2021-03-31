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
    var selectedItems = [IndexPath](), loadingSectionIndexPaths = [IndexPath]()
    var selectAllSections = [Int]()
    
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
            let isLoading = loadingSectionIndexPaths.contains(indexPath)
            cell.reloadButton.tag = indexPath.section
            cell.activityIndicator.isHidden = !isLoading
            if isLoading {
                cell.activityIndicator.startAnimating()
            } else {
                cell.activityIndicator.stopAnimating()
            }
            cell.reloadButton.isHidden = isLoading
            cell.buttonTapCallback = { [weak self] sender in self?.loadUsersFor(section: indexPath.section) }
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
            sectionHeader.sectionHeaderNameLable.text = "Section - \(indexPath.section + 1)"
            sectionHeader.buttonTapCallback = {[weak self] sender in self?.selectAllCell(section: indexPath.section)}
            sectionHeader.selectButton.isHidden = !isCollectionEditing
            return sectionHeader
        }
        return UICollectionReusableView()
    }
    override func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        return indexPath.item != 0 && !isCollectionEditing
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
    
    func loadUsersFor(section:Int) {
        let indexPath = IndexPath(item: 0, section: section)
        loadingSectionIndexPaths.append(indexPath)
        collectionView.reloadItems(at: [indexPath])
        
        retrieveUserFor(lastUserId:  myUsers[section].last?.id) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let users):
                self.saveUserData(users, section: section)
                self.myUsers[section] = self.fetchData(section: section)
            case .failure(let runtimeError):
                print(runtimeError)
            }
            if let index = self.loadingSectionIndexPaths.firstIndex(of: indexPath) {
                self.loadingSectionIndexPaths.remove(at: index)
            }
            self.collectionView.reloadData()
        }
    }
    
    func selectAllCell(section:Int) {
        guard isCollectionEditing else { return }
        
        if selectAllSections.contains(section) {
            selectAllSections.removeAll(where: { $0 == section })
            let indexPathToDeselect = (1..<collectionView.numberOfItems(inSection: section)).map({ IndexPath(item: $0, section: section) })
            selectedItems.removeAll(where: { indexPathToDeselect.contains($0) })
        } else {
            selectAllSections.append(section)
            for index in 1..<collectionView.numberOfItems(inSection: section) {
                let indexPath = IndexPath(item: index, section: section)
                if !selectedItems.contains(indexPath) {
                    selectedItems.append(indexPath)
                }
            }
        }
        
        collectionView.reloadSections(IndexSet(integer: section))
    }
    
    //MARL: Downloading JSON
    func retrieveUserFor(lastUserId:Int?, comppletionBlock: @escaping ((Result<[User], RuntimeError>)) -> Void) {
        var urlCom = URLComponents(string: "https://api.github.com/users")
        
        var queryItem = [URLQueryItem]()
        if let id = lastUserId {
            queryItem.append(.init(name: "since", value: String(id)))
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
                    comppletionBlock(.failure(.underlyingError(error: error)))
                }
            } else {
                do {
                    let users = try JSONDecoder().decode([User].self, from: data!)
                    DispatchQueue.main.async{
                        comppletionBlock(.success(users))
                    }
                } catch let error {
                    print("JSON Error")
                    DispatchQueue.main.async{
                        comppletionBlock(.failure(.decodingError(error: error)))
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


enum RuntimeError: Error {
    case connectionError
    case decodingError(error: Error?)
    case underlyingError(error:Error?)
}
