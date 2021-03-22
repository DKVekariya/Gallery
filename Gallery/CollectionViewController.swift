//
//  CollectionViewController.swift
//  Gallery
//
//  Created by Divyesh Vekariya on 20/03/21.
//

import UIKit

private let reuseIdentifier = "Cell"

class CollectionViewController: UICollectionViewController {
    
    var users = [User]()

    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    override func viewDidLoad() {
        super.viewDidLoad()
        downloadJson(completed: onSuccess(_:), errorblock: onError(_:))
    }
    
    func onSuccess(_ users:[User]) {
        self.users = users
        collectionView.reloadData()
    }
    
    func onError(_ error: Error) {
        print(error)
    }
    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return users.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! CollectionViewCell
        cell.imageView.downloaded(from: users[indexPath.row].avatar_url)
        return cell
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
