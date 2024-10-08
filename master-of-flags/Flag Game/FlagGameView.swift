import SwiftUI

struct FlagGameView: View {

    @StateObject var manager: FlagGameManager

    var body: some View {
        VStack {
            Picker(selection: $manager.activePickerValue, label: Text("Pick region")) {
                ForEach(0..<manager.regions.count, id: \.self) {
                    Text(manager.regions[$0].title)
                }
            }
            .pickerStyle(.segmented)

            FlagGameHeaderView(
                answer: manager.countries[manager.correctAnswer],
                score: manager.score,
                level: manager.playerLevel,
                streak: manager.streak
            )

            if manager.isHardModeEnabled {
                ScrollView {
                    LazyVGrid(columns: manager.flagGridColumns) {
                        ForEach(0..<8) { number in
                            Button {
                                manager.flagTapped(number)
                            } label: {
                                Image(manager.countries[number])
                                    .flagImageMofifier()
                            }
                            .rotation3DEffect(
                                .degrees(number == manager.correctAnswer ? manager.rotation : 0),
                                axis: (x: 1, y: 0, z: 0)
                            )
                        }
                    }
                }
            } else {
                ForEach(0..<3) { number in
                    Button {
                        manager.flagTapped(number)
                    } label: {
                        Image(manager.countries[number])
                            .flagImageMofifier()
                    }
                    .rotation3DEffect(
                        .degrees(number == manager.correctAnswer ? manager.rotation : 0),
                        axis: (x: 1, y: 0, z: 0)
                    )
                }
            }

            // test id
            GoogleAdBannerView(unitID: GoogleAdIdentifiers.bottom_banner_flag_game)
                .frame(height: 50)
        }
        .padding(.horizontal, 8)
        .padding(.bottom, 4)
        .alert(isPresented: $manager.showingScore) {
            Alert(
                title: Text(manager.scoreTitle),
                message: Text(manager.alertMessage),
                dismissButton: .default(Text("Next ⏭")) { manager.askQuestion() }
            )
        }
        .onAppear { manager.askQuestion() }
    }
}

struct TabBar_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            FlagGameView(manager: FlagGameManager(settings: Settings()))
            FlagGameView(manager: FlagGameManager(settings: Settings()))
                .preferredColorScheme(.dark)
                .previewDevice("iPhone SE (1st generation)")
        }
    }
}
