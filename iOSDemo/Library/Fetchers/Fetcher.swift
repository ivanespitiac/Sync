import CoreData
import Sync
import Alamofire

class Fetcher {
    private let dataStack: DataStack

    init() {
        self.dataStack = DataStack(modelName: "DataModel", bundle: Bundle(for: Fetcher.self), storeType: .sqLite)
    }

    func fetchLocalUsers() -> [User] {
        let request: NSFetchRequest<User> = User.fetchRequest()
        return try! self.dataStack.viewContext.fetch(request)
    }

    func syncUsingAlamofire(completion: @escaping (_ result: VoidResult) -> ()) {
        
        AF.request("https://jsonplaceholder.typicode.com/users").responseString { response in
            if let data = response.value?.data(using: .utf8) {
                do {
                    if let jsonArray = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as? [Dictionary<String, Any>] {
                        self.dataStack.sync(jsonArray, inEntityNamed: User.entity().name ?? "") { error in
                            completion(.success)
                        }
                    } else {
                        
                    }
                } catch let error as NSError {
                    completion(.failure(error))
                }
            } else if let error = response.error {
                completion(.failure(error as NSError))
            } else {
                fatalError("No error, no failure")
            }
        }
               
    }

    func syncUsingLocalJSON(completion: @escaping (_ result: VoidResult) -> ()) {
        
        let data : [[String: Any]] = [
            [ "id" : "1", "name" : "Prueba 1", "beers": [ ["id":"1", "name":"pilsen"] ] ],
            [ "id" : "2", "name" : "Prueba 2" ],
            [ "id" : "3", "name" : "Prueba 3" ]]

        self.dataStack.sync(data, inEntityNamed: User().entity.name ?? "") { error in
            completion(.success)
        }
        
        completion(.success)
        
    }
}

enum VoidResult {
    case success
    case failure(NSError)
}
