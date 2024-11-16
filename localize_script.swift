import Foundation

// Path to the original file
let inputFilePath = "original_code.swift"
let outputFilePath = "localized_code.swift"

// Read the file contents
guard let inputCode = try? String(contentsOfFile: inputFilePath) else {
    print("Failed to read the input file.")
    exit(1)
}

// Regex pattern to match tuples like ("key", "value")
let pattern = #"\("([^"]+)",\s*"([^"]+)"\)"#

// Replace function to wrap the value in NSLocalizedString while keeping the tuple intact
let localizedCode = inputCode.replacingOccurrences(
    of: pattern,
    with: #"\("$1", NSLocalizedString("$2", comment: ""))"#,
    options: .regularExpression
)

// Write the localized code to a new file
do {
    try localizedCode.write(toFile: outputFilePath, atomically: true, encoding: .utf8)
    print("Localized code has been written to \(outputFilePath).")
} catch {
    print("Failed to write the localized code: \(error)")
}

