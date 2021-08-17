//
//  ViewController.swift
//  Project5
//
//  Created by Eddie Jung on 8/4/21.
//

import UIKit

class ViewController: UITableViewController {
    var allWords = [String]()
    var usedWords = Entry()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Start Game", style: .plain, target: self, action: #selector(startGame))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(promptForAnswer))
        
        DispatchQueue.global().async { [weak self] in
            if let startWordsURL = Bundle.main.url(forResource: "start", withExtension: "txt") {
                if let startWords = try? String(contentsOf: startWordsURL) {
                    self?.allWords = startWords.components(separatedBy: "\n")
                }
            }
            
            if ((self?.allWords.isEmpty) == nil) {
                self?.allWords = ["silkworm"]
            }
            
            DispatchQueue.main.async {
                self?.load()
                
                if self?.usedWords.entries == [] && self?.usedWords.title == "" {
                    self?.startGame()
                }
            }
        }
        
        
    }

    @objc func startGame() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "entry")
        
        title = allWords.randomElement()
        
        usedWords.title = title ?? ""
        usedWords.entries.removeAll(keepingCapacity: true)
        
        save()
        tableView.reloadData()
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return usedWords.entries.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Word", for: indexPath)
        cell.textLabel?.text = usedWords.entries[indexPath.row]
        return cell
    }
    
    @objc func promptForAnswer() {
        let ac = UIAlertController(title: "Enter answer", message: nil, preferredStyle: .alert)
        ac.addTextField()
        
        let submitAction = UIAlertAction(title: "Submit", style: .default) {
            [weak self, weak ac] _ in
            guard let answer = ac?.textFields?[0].text else { return }
            self?.submit(answer)
        }
        
        ac.addAction(submitAction)
        present(ac, animated: true)
    }
    
    func submit(_ answer: String) {
        let lowerAnswer = answer.lowercased()
        
        let errorTitle: String
        let errorMessage: String
        
        if isPossible(word: lowerAnswer) {
            if isOriginal(word: lowerAnswer) {
                if isReal(word: lowerAnswer) {
                    usedWords.entries.insert(lowerAnswer, at: 0)
                    save()
                    
                    let indexPath = IndexPath(row: 0, section: 0)
                    tableView.insertRows(at: [indexPath], with: .automatic)
                    
                    return
                } else {
                    errorTitle = "Word not recognized"
                    errorMessage = "You can't just make them up, you know!"
                    
                    showErrorMessage(errorTitle, errorMessage)
                }
            } else {
                errorTitle = "Word already used"
                errorMessage = "Be more original!"
                
                showErrorMessage(errorTitle, errorMessage)
            }
        } else {
            guard let title = title else { return }
            errorTitle = "Word not possible"
            errorMessage = "You can't spell that word from \(title.lowercased())."
            
            showErrorMessage(errorTitle, errorMessage)
        }
    }
    
    // is the answer made from the given word
    func isPossible(word: String) -> Bool {
        guard var tempWord = title?.lowercased() else { return false }
        
        if tempWord == word { return false }
        
        for letter in word {
            if let position = tempWord.firstIndex(of: letter) {
                tempWord.remove(at: position)
            } else {
                return false
            }
        }
        
        return true
    }
    
    // has the answer been already used
    func isOriginal(word: String) -> Bool {
        return !usedWords.entries.contains(word)
    }
    
    // is it an actual word
    func isReal(word: String) -> Bool {
        
        if word.count < 3 { return false }
        
        let checker = UITextChecker()
        let range = NSRange(location: 0, length: word.utf16.count)
        let misspelledRange = checker.rangeOfMisspelledWord(in: word, range: range, startingAt: 0, wrap: false, language: "en")
        return misspelledRange.location == NSNotFound
    }
    
    func showErrorMessage(_ errorTitle: String, _ errorMessage: String) {
        let ac = UIAlertController(title: errorTitle, message: errorMessage, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }
    
    func load() {
        let defaults = UserDefaults.standard
        
        if let savedEntry = defaults.object(forKey: "entry") as? Data {
            let jsonDecoder = JSONDecoder()
            
            do {
                usedWords = try jsonDecoder.decode(Entry.self, from: savedEntry)
                title = usedWords.title
                tableView.reloadData()
            } catch {
                print("Failed to load entry.")
            }
        }
    }
    
    func save() {
        let jsonEncoder = JSONEncoder()
        
        if let savedData = try? jsonEncoder.encode(usedWords) {
            let defaults = UserDefaults.standard
            
            defaults.set(savedData, forKey: "entry")
        } else {
            print("Failed to load entry.")
        }
        
    }

}

