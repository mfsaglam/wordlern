
import Foundation

// Define the structure of the JSON data
struct WordData: Codable {
    let rank: Int
    let targetWord: String
    let englishWord: String
}

struct LanguageData: Codable {
    let languageCode: String
    let languageName: String
    let languageNativeName: String
    let words: [WordData]
}

// Load the JSON data from a file
func loadJSON(from fileName: String) -> LanguageData? {
    let fileURL = URL(fileURLWithPath: fileName)
    do {
        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        let decodedData = try decoder.decode(LanguageData.self, from: data)
        return decodedData
    } catch {
        print("Error loading or parsing the JSON file: \(error)")
        return nil
    }
}

// Generate the Localizable.strings content
func generateLocalizableStrings(from languageData: LanguageData) -> String {
    var localizableContent = [String]()
    
    for word in languageData.words {
        let englishWord = word.englishWord
        let localizableEntry = "\"\(englishWord)\" = \"\(englishWord)\";"
        localizableContent.append(localizableEntry)
    }
    
    return localizableContent.joined(separator: "\n")
}

// Write the content to a Localizable.strings file
func writeToFile(content: String, languageCode: String) {
    let fileName = "Localizable_\(languageCode).strings"
    let fileURL = URL(fileURLWithPath: fileName)
    
    do {
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
        print("Localizable.strings file created: \(fileName)")
    } catch {
        print("Error writing to file: \(error)")
    }
}

// Main logic
let jsonFileName = "words.json" // Replace with your JSON file name
if let languageData = loadJSON(from: jsonFileName) {
    let localizableContent = generateLocalizableStrings(from: languageData)
    writeToFile(content: localizableContent, languageCode: languageData.languageCode)
} else {
    print("Failed to load or parse the JSON data.")
}
