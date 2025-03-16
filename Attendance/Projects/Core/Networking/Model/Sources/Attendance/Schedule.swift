//
//  Schedule.swift
//  Model
//
//  Created by 홍은표 on 3/16/25.
//

import Foundation

public struct Schedule: Identifiable, Equatable {
  public let id: String
  public let month: Int
  public let day: Int
  public let title: String
  public let description: String
  public let state: AttendanceType
  
  public init(
    id: String,
    month: Int,
    day: Int,
    title: String,
    description: String,
    state: AttendanceType
  ) {
    self.id = id
    self.month = month
    self.day = day
    self.title = title
    self.description = description
    self.state = switch state {
    case .present, .late, .absent:
      state
    default:
      .notAttendance
    }
  }
  
  public static func ==(lhs: Schedule, rhs: Schedule) -> Bool {
    return lhs.id == rhs.id
  }
}
