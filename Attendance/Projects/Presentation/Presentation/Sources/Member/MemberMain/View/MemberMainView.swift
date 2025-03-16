//
//  MemberMainView.swift
//  Presentation
//
//  Created by 홍은표 on 1/2/25.
//

import SwiftUI

import DesignSystem

import ComposableArchitecture

struct MemberMainView: View {
  @Bindable private var store: StoreOf<MemberMain>
  
  init(store: StoreOf<MemberMain>) {
    self.store = store
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing: .zero) {
      navigationBar
      
      ScrollView {
        VStack(alignment: .leading, spacing: 56) {
          attendanceStatus
          
          scheduleList
        }
        .padding(.horizontal, 24)
      }
    }
    .customAlert(
      isPresented: store.showWarningAlert,
      title: "주의해주세요!",
      message: "2번 지각 시 노쇼비를 돌려받을 수 없습니다.",
      onConfirm: {
        store.send(.view(.didTapDismissAlertButton))
      }
    )
    .task {
      store.send(.async(.fetchCurrentUser))
    }
  }
  
  private var navigationBar: some View {
    HStack(spacing: .zero) {
      Image(asset: ImageAsset.appLogo)
        .renderingMode(.template)
        .resizable()
        .scaledToFit()
        .frame(width: 25, height: 28)
        .foregroundStyle(.gray60)
      
      Spacer()
      
      HStack(spacing: 12) {
        Button(action: {
          store.send(.navigation(.presentQRCode))
        }) {
          Image(asset: ImageAsset.qrCode)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: 20, height: 20)
            .foregroundStyle(.staticWhite)
        }
        .frame(width: 36, height: 36)
        .background(.blue70)
        .clipShape(.rect(cornerRadius: 99))
        .overlay(
          RoundedRectangle(cornerRadius: 99)
            .stroke(Color.blue30, lineWidth: 1)
        )
        
        Button(action: {
          store.send(.navigation(.routeToProfile))
        }) {
          Image(asset: ImageAsset.managementProfile)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: 20, height: 20)
            .foregroundStyle(.staticWhite)
        }
        .frame(width: 36, height: 36)
        .background(.gray80)
        .clipShape(RoundedRectangle(cornerRadius: 99))
      }
    }
    .frame(height: 52)
    .padding(.horizontal, 24)
  }
  
  private var attendanceStatus: some View {
    VStack(alignment: .leading, spacing: 16) {
      if let member = store.state.member {
        Text("\(member.name)님의 출석 현황")
          .pretendardFont(family: .Bold, size: 28)
          .foregroundStyle(.textPrimary)
        
        VStack(alignment: .leading, spacing: 8) {
          // TODO: - 활동 기간 표시
          Text("활동 기간: 1970.01.01 ~ 1970.01.01")
            .pretendardFont(family: .Regular, size: 14)
            .foregroundStyle(.textSecondary)
          
          // TODO: - 출석 현황 표시
          AttendanceCard(
            attendanceCount: 8,
            lateCount: 1,
            absentCount: 2,
            isManager: false,
            onTapAbsentButton: {
              store.send(.view(.didTapAbesentButton))
            }
          )
        }
      }
    }
    .padding(.top, 20)
  }
  
  private var scheduleList: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("12기 일정표")
        .pretendardFont(family: .Medium, size: 24)
        .foregroundStyle(.textPrimary)
      
      LazyVStack(alignment: .leading, spacing: 12) {
        ForEach(store.schedules) {
          ScheduleCell(
            month: $0.month,
            day: $0.day,
            title: $0.title,
            description: $0.description
          )
        }
      }
    }
  }
}

private struct ScheduleCell: View {
  private let month: Int
  private let day: Int
  private let title: String
  private let description: String
  private let stampImage: Image?
  private let backgroundColor: Color
  private let isDashBorderLine: Bool
  
  init(
    month: Int,
    day: Int,
    title: String,
    description: String,
    stampImage: Image?,
    backgroundColor: Color,
    isDashBorderLine: Bool
  ) {
    self.month = month
    self.day = day
    self.title = title
    self.description = description
    self.stampImage = stampImage
    self.backgroundColor = backgroundColor
    self.isDashBorderLine = isDashBorderLine
  }
  
  var body: some View {
    HStack(alignment: .center, spacing: .zero) {
      VStack(alignment: .center, spacing: 4) {
        Text("\(month)월")
          .pretendardFont(family: .Regular, size: 14)
          .foregroundStyle(.staticBlack)
        
        Text("\(day)")
          .pretendardFont(family: .Medium, size: 14)
          .foregroundStyle(.staticBlack)
      }
      .padding(.vertical, 8)
      .padding(.horizontal, 16)
      .background(.blue20)
      .clipShape(.rect(cornerRadius: 12))
      
      VStack(alignment: .leading, spacing: .zero) {
        Text(title)
          .pretendardFont(family: .Bold, size: 18)
          .foregroundStyle(.backgroundInverse)
        
        Text(description)
          .pretendardFont(family: .Regular, size: 14)
          .foregroundStyle(.textSecondary)
      }
      .padding(.leading, 12)
      
      Spacer()
    }
    .padding(16)
    .background(.gray90)
    .clipShape(.rect(cornerRadius: 16))
    .listRowSeparator(.hidden)
    .listRowInsets(.init(.zero))
  }
}
