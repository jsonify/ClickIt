import Foundation

/// Generates Sparkle-compatible appcast XML from GitHub Releases API data
struct AppcastGenerator {
    
    // MARK: - Data Models
    
    struct GitHubRelease: Codable {
        let id: Int
        let tagName: String
        let name: String?
        let body: String?
        let prerelease: Bool
        let draft: Bool
        let publishedAt: String?
        let assets: [GitHubAsset]
        let htmlUrl: String
        
        private enum CodingKeys: String, CodingKey {
            case id, name, body, prerelease, draft, assets
            case tagName = "tag_name"
            case publishedAt = "published_at"
            case htmlUrl = "html_url"
        }
    }
    
    struct GitHubAsset: Codable {
        let id: Int
        let name: String
        let size: Int
        let downloadCount: Int
        let browserDownloadUrl: String
        
        private enum CodingKeys: String, CodingKey {
            case id, name, size
            case downloadCount = "download_count"
            case browserDownloadUrl = "browser_download_url"
        }
    }
    
    // MARK: - Configuration
    
    struct AppcastConfig {
        let appName: String
        let bundleId: String
        let repository: String
        let minimumSystemVersion: String
        let includeBetaReleases: Bool
        
        static let `default` = AppcastConfig(
            appName: "ClickIt",
            bundleId: AppConstants.appcastURL.contains("clickit") ? "com.jsonify.clickit" : "com.example.clickit",
            repository: AppConstants.githubRepository,
            minimumSystemVersion: AppConstants.minimumOSVersion,
            includeBetaReleases: false
        )
    }
    
    // MARK: - Public Methods
    
    /// Fetches GitHub releases and generates appcast XML
    static func generateAppcast(config: AppcastConfig = .default) async throws -> String {
        let releases = try await fetchGitHubReleases(repository: config.repository)
        let filteredReleases = filterReleases(releases, includeBeta: config.includeBetaReleases)
        return generateAppcastXML(releases: filteredReleases, config: config)
    }
    
    /// Generates appcast XML from provided releases data
    static func generateAppcastXML(releases: [GitHubRelease], config: AppcastConfig) -> String {
        let items = releases.compactMap { release -> String? in
            generateAppcastItem(release: release, config: config)
        }
        
        return generateFullAppcast(items: items, config: config)
    }
    
    // MARK: - Private Methods
    
    /// Fetches releases from GitHub API
    private static func fetchGitHubReleases(repository: String) async throws -> [GitHubRelease] {
        guard let url = URL(string: "https://api.github.com/repos/\(repository)/releases") else {
            throw AppcastError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            throw AppcastError.networkError
        }
        
        do {
            return try JSONDecoder().decode([GitHubRelease].self, from: data)
        } catch {
            throw AppcastError.decodingError(error)
        }
    }
    
    /// Filters releases based on configuration
    private static func filterReleases(_ releases: [GitHubRelease], includeBeta: Bool) -> [GitHubRelease] {
        return releases.filter { release in
            // Skip drafts
            guard !release.draft else { return false }
            
            // Include/exclude prerelease based on configuration
            if release.prerelease && !includeBeta {
                return false
            }
            
            // Must have at least one asset
            return !release.assets.isEmpty
        }
        .sorted { lhs, rhs in
            // Sort by published date, newest first
            guard let lhsDate = parseDate(lhs.publishedAt),
                  let rhsDate = parseDate(rhs.publishedAt) else {
                return false
            }
            return lhsDate > rhsDate
        }
    }
    
    /// Generates individual appcast item XML
    private static func generateAppcastItem(release: GitHubRelease, config: AppcastConfig) -> String? {
        // Find the main app asset (typically .zip or .dmg)
        guard let mainAsset = findMainAsset(in: release.assets) else {
            return nil
        }
        
        let version = extractVersion(from: release.tagName)
        let title = release.name ?? "\(config.appName) \(version)"
        let description = formatReleaseNotes(release.body)
        let pubDate = formatPubDate(release.publishedAt)
        
        return """
        <item>
            <title><![CDATA[\(title)]]></title>
            <description><![CDATA[\(description)]]></description>
            <link>\(release.htmlUrl)</link>
            <sparkle:version>\(version)</sparkle:version>
            <sparkle:shortVersionString>\(version)</sparkle:shortVersionString>
            <sparkle:minimumSystemVersion>\(config.minimumSystemVersion)</sparkle:minimumSystemVersion>
            <pubDate>\(pubDate)</pubDate>
            <enclosure url="\(mainAsset.browserDownloadUrl)" 
                       length="\(mainAsset.size)" 
                       type="application/octet-stream" 
                       sparkle:version="\(version)" 
                       sparkle:shortVersionString="\(version)" />
        </item>
        """
    }
    
    /// Finds the main downloadable asset (ZIP or DMG)
    private static func findMainAsset(in assets: [GitHubAsset]) -> GitHubAsset? {
        // Prefer ZIP files for auto-updates, then DMG
        return assets.first { asset in
            asset.name.lowercased().hasSuffix(".zip")
        } ?? assets.first { asset in
            asset.name.lowercased().hasSuffix(".dmg")
        }
    }
    
    /// Extracts version number from Git tag
    private static func extractVersion(from tagName: String) -> String {
        // Remove common prefixes like "v", "beta-v", etc.
        let cleanTag = tagName.replacingOccurrences(of: "^(beta-)?v?", with: "", options: .regularExpression)
        return cleanTag.isEmpty ? tagName : cleanTag
    }
    
    /// Formats release notes for XML
    private static func formatReleaseNotes(_ body: String?) -> String {
        guard let body = body, !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return "No release notes available."
        }
        
        // Basic HTML conversion for better display
        let formatted = body
            .replacingOccurrences(of: "### ", with: "<h3>")
            .replacingOccurrences(of: "## ", with: "<h2>")
            .replacingOccurrences(of: "# ", with: "<h1>")
            .replacingOccurrences(of: "\n", with: "<br>")
        
        return formatted
    }
    
    /// Formats publication date for RSS
    private static func formatPubDate(_ publishedAt: String?) -> String {
        guard let publishedAt = publishedAt,
              let date = parseDate(publishedAt) else {
            return RFC822DateFormatter.string(from: Date())
        }
        
        return RFC822DateFormatter.string(from: date)
    }
    
    /// Parses ISO 8601 date string
    private static func parseDate(_ dateString: String?) -> Date? {
        guard let dateString = dateString else { return nil }
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        return formatter.date(from: dateString) ?? ISO8601DateFormatter().date(from: dateString)
    }
    
    /// Generates complete appcast XML structure
    private static func generateFullAppcast(items: [String], config: AppcastConfig) -> String {
        let itemsXML = items.joined(separator: "\n        ")
        let lastBuildDate = RFC822DateFormatter.string(from: Date())
        
        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" xmlns:dc="http://purl.org/dc/elements/1.1/">
            <channel>
                <title>\(config.appName) Updates</title>
                <link>https://github.com/\(config.repository)</link>
                <description>Software updates for \(config.appName)</description>
                <language>en</language>
                <lastBuildDate>\(lastBuildDate)</lastBuildDate>
                
        \(itemsXML)
                
            </channel>
        </rss>
        """
    }
    
    // MARK: - Date Formatter
    
    private static let RFC822DateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(abbreviation: "GMT")
        return formatter
    }()
}

// MARK: - Error Types

enum AppcastError: Error, LocalizedError {
    case invalidURL
    case networkError
    case decodingError(Error)
    case noValidReleases
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid GitHub API URL"
        case .networkError:
            return "Network request failed"
        case .decodingError(let error):
            return "Failed to decode GitHub API response: \(error.localizedDescription)"
        case .noValidReleases:
            return "No valid releases found"
        }
    }
}

// MARK: - Convenience Extensions

extension AppcastGenerator {
    
    /// Generates appcast for beta releases
    static func generateBetaAppcast() async throws -> String {
        var config = AppcastConfig.default
        config = AppcastConfig(
            appName: config.appName,
            bundleId: config.bundleId,
            repository: config.repository,
            minimumSystemVersion: config.minimumSystemVersion,
            includeBetaReleases: true
        )
        return try await generateAppcast(config: config)
    }
    
    /// Validates that the generated XML is well-formed
    static func validateAppcastXML(_ xml: String) -> Bool {
        guard let data = xml.data(using: .utf8) else { return false }
        
        let parser = XMLParser(data: data)
        let delegate = XMLValidationDelegate()
        parser.delegate = delegate
        
        return parser.parse() && !delegate.hasError
    }
}

// MARK: - XML Validation

private class XMLValidationDelegate: NSObject, XMLParserDelegate {
    var hasError = false
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        hasError = true
    }
    
    func parser(_ parser: XMLParser, validationErrorOccurred validationError: Error) {
        hasError = true
    }
}