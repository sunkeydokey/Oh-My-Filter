//
//  ApiRouter.swift
//  Oh-My-Filter
//
//  Created by 이선기 on 4/24/26.
//

import Foundation

nonisolated protocol ApiRouter {
  var url: String { get }
  var method: HttpMethod { get }
  var contentType: ContentType { get }
}
