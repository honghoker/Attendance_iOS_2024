//
//  Schedule.swift
//  DDDAttendance
//
//  Created by eunpyo on 4/13/25.
//

import Foundation

public struct Schedule: Identifiable, Equatable {
  public let id: String
  public let month: Int
  public let day: Int
  public let title: String
  public let description: String
  public let status: AttendanceStatus

  public init(
    id: String,
    month: Int,
    day: Int,
    title: String,
    description: String,
    status: AttendanceStatus
  ) {
    self.id = id
    self.month = month
    self.day = day
    self.title = title
    self.description = description
    self.status = status
  }

  public static func ==(lhs: Schedule, rhs: Schedule) -> Bool {
    return lhs.id == rhs.id
  }
}
