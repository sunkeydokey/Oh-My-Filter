//
//  Server.swift
//  Oh-My-Filter
//
//  Created by 이선기 on 4/22/26.
//

import Foundation

enum Server {
  nonisolated static func apiKey() -> String {
    guard let key = Bundle.main.object(
      forInfoDictionaryKey: "API_KEY"
    ) as? String else { return "NO API KEY" }

    return key
  }

  nonisolated static func baseUrl() -> String {
    guard let host = Bundle.main.object(
      forInfoDictionaryKey: "HTTP_HOST"
    ) as? String else { return "HTTP 도메인을 찾을 수 없음" }
    guard let port = Bundle.main.object(
      forInfoDictionaryKey: "HTTP_PORT"
    ) as? String else { return "HTTP PORT를 찾을 수 없음" }
    guard let version = Bundle.main.object(
      forInfoDictionaryKey: "API_VERSION"
    ) as? String else { return "API 버전을 찾을 수 없음" }
    return "http://\(host):\(port)/\(version)"
  }
}
