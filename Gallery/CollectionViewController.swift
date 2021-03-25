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
    
    var users = [User]()
    var sectonItem = ["section","section"]
    var myUsers = [User]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
       // downloadJson(completed: onSuccess(_:), errorblock: onError(_:))
        fetchData()
        collectionView.reloadData()
    }
    
//    func onSuccess(_ users:[User]) {
//        saveUserData(users)
//        fetchData()
//        self.users = users
//
//    }
//
//    func onError(_ error: Error) {
//        print(error)
//    }
    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return sectonItem.count
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return myUsers.count + 1
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.row == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reloadCellReuseIdentifier, for: indexPath) as! ReloadCollectionViewCell
            cell.reloadButton.tag = indexPath.section
            cell.buttonTapCallback = { [weak self, weak collectionView] sender in
                print((sender as! UIButton).tag)
                print("Button taped \(indexPath.section)")
                collectionView?.deleteItems(at: [indexPath])
                self?.downloadJson { (_ users: [User]) in
                    self?.saveUserData(users)
                } errorblock: { (Error) in
                    print("error\(Error)")
                }

            }
            return cell
        }
        else {
            if indexPath.section == 0 {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! CollectionViewCell
                cell.imageView.downloaded(from: myUsers[indexPath.row-1].avatar_url )
                    return cell
            } else{
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! CollectionViewCell
                cell.imageView.downloaded(from: myUsers[indexPath.row-1].avatar_url )
                    return cell
            }
        
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        return CGSize(width: (collectionView.frame.width-16)/2 , height: (collectionView.frame.height-32)/3)
    }
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {

        if let sectionHeader = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: reuseViewIdentifier, for: indexPath) as? CollectionReusableView{
            sectionHeader.sectionHeaderNameLable.text = "Section\(indexPath.section)"
            return sectionHeader
        }
        return UICollectionReusableView()
    }

    // MARK: UICollectionViewDelegate

    func downloadJson(completed: @escaping ([User]) -> (), errorblock: @escaping ( (Error) -> () )) {
            let url = URL(string:"https://api.github.com/users")
            URLSession.shared.dataTask(with: url!) { (data, response, error) in
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
    func saveUserData(_ users: [User]) {
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        for user in users {
            if context.hasChanges {
                do {
                let newUser = NSEntityDescription.insertNewObject(forEntityName: "Person", into: context)
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
    }
    //Fatch core data
    func fetchData() {

        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Person")

        do {
            let result = try context.fetch(fetchRequest) as! [NSManagedObject]
            
            for item in result {
                let idtag = item.value(forKey: "idtag") as! Int
                let imagePath = item.value(forKey: "imagelink") as! String
                let username = item.value(forKey: "username") as! String
                myUsers.append(User(login: username, id: idtag, avatar_url: imagePath))
            }
        }catch let err as NSError {
            print(err.debugDescription)
        }
    }



    //Update core data
    //Delete from core data
    
}

extension UIImageView {
    func downloaded(from url: URL, contentMode mode: UIView.ContentMode = .scaleAspectFit) {
        contentMode = mode
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard
                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data, error == nil,
                let image = UIImage(data: data)
                else { return }
            DispatchQueue.main.async() { [weak self] in
                self?.image = image
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
