import SwiftUI
import PhotosUI

extension Date {
    func dayValue() -> Int {
        return Calendar.current.component(.day, from: self)
    }
    func monthValue() -> Int {
        return Calendar.current.component(.month, from: self)
    }
    func yearValue() -> Int {
        return Calendar.current.component(.year, from: self)
    }
    func dayEqual(to day: Int) -> Bool {
        return self.dayValue() == day
    }
}

struct MonthCalendarView: View {
    @Binding var selectedDate: Date
    @State private var displayedMonth: Date = Date() // new state for displayed month

    init(selectedDate: Binding<Date>) {
        self._selectedDate = selectedDate
        self._displayedMonth = State(initialValue: Calendar.current.startOfDay(for: selectedDate.wrappedValue))
    }
    
    private func countFor(day: Int) -> Int {
        let calendar = Calendar.current
        var comps = calendar.dateComponents([.year, .month], from: displayedMonth)
        comps.day = day
        guard let date = calendar.date(from: comps) else { return 0 }
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "creationDate >= %@ AND creationDate < %@", startOfDay as NSDate, endOfDay as NSDate)
        return PHAsset.fetchAssets(with: .image, options: fetchOptions).count
    }
    
    private func colorForCount(_ count: Int) -> Color {
        let normalized = min(Double(count) / 100.0, 1.0)
        return Color(red: normalized, green: 1.0 - normalized, blue: 0.0)
    }
    
    private var monthYearHeader: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL yyyy"
        return formatter.string(from: displayedMonth)
    }
    
    var body: some View {
        VStack {
            // Month Navigation Header
            HStack {
                Button(action: {
                    if let newMonth = Calendar.current.date(byAdding: .month, value: -1, to: displayedMonth) {
                        displayedMonth = newMonth
                    }
                }) {
                    Image(systemName: "chevron.left")
                }
                Spacer()
                Text(monthYearHeader)
                    .font(.headline)
                Spacer()
                Button(action: {
                    if let newMonth = Calendar.current.date(byAdding: .month, value: 1, to: displayedMonth) {
                        displayedMonth = newMonth
                    }
                }) {
                    Image(systemName: "chevron.right")
                }
            }
            .padding(.horizontal)
            
            // Days of Week Header
            HStack {
                ForEach(["Пн","Вт","Ср","Чт","Пт","Сб","Вс"], id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Days Grid with offset
            let calendar = Calendar.current
            let comps = calendar.dateComponents([.year, .month], from: displayedMonth)
            let startOfMonth = calendar.date(from: comps)!
            let range = calendar.range(of: .day, in: .month, for: startOfMonth)!
            let firstWeekday = calendar.component(.weekday, from: startOfMonth)
            // Adjust offset assuming Monday is first day
            let offset = (firstWeekday + 5) % 7
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                ForEach(0..<offset, id: \.self) { _ in
                    Text("")
                }
                ForEach(Array(range), id: \.self) { day in
                    let count = countFor(day: day)
                    let color = colorForCount(count)
                    Button(action: {
                        var comps = calendar.dateComponents([.year, .month, .day], from: displayedMonth)
                        comps.day = day
                        if let newDate = calendar.date(from: comps) {
                            selectedDate = newDate
                        }
                    }) {
                        VStack {
                            Text("\(day)")
                            Text("\(count)")
                                .font(.footnote)
                                .foregroundColor(color)
                        }
                        .padding(4)
                        .background(
                            (calendar.component(.day, from: selectedDate) == day &&
                             calendar.component(.month, from: selectedDate) == calendar.component(.month, from: displayedMonth) &&
                             calendar.component(.year, from: selectedDate) == calendar.component(.year, from: displayedMonth))
                            ? Color.blue.opacity(0.3) : Color.clear
                        )
                        .cornerRadius(4)
                    }
                }
            }
        }
    }
}

struct ContentView: View {
    @State private var photos: [UIImage] = [] // Хранение выбранных фотографий
    @State private var photoAssets: [PHAsset] = [] // Хранение PHAsset для удаления
    @State private var currentIndex: Int = 0
    @State private var savedPhotos: [UIImage] = []
    @State private var removedPhotos: [UIImage] = []
    @State private var swipeOffset: CGFloat = 0 // Смещение для анимации
    @State private var isAnimating: Bool = false // Флаг для блокировки действий во время анимации
    @State private var topPhotoColor: Color = .clear // Цвет верхней фотографии
    @State private var bottomPhotoColor: Color = .clear // Цвет нижней фотографии
    @State private var showingPhotoPicker = false // Флаг для отображения PHPickerViewController
    @State private var allAssets: PHFetchResult<PHAsset>? = nil   // New: store all photo assets
    @State private var fetchBatchSize: Int = 100                    // New: batch size (i.e. 50 pairs)
    @State private var selectedDate: Date = Date() // New: Date selection state
    @State private var photoCountForDate: Int = 0   // New: count of photos for the selected date

    var body: some View {
        VStack {
            if photos.isEmpty {
                VStack {
                    // NEW: Instead of a DatePicker, show the custom calendar view.
                    MonthCalendarView(selectedDate: $selectedDate)
                        .padding(.bottom, 8)
                    Button("Загрузить фотографии") {
                        fetchPhotosByDate()
                    }
                    .padding()
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(10)
                }
            } else if currentIndex < photos.count - 1 {
                Text("Пара \(currentIndex / 2 + 1) из \(photos.count / 2)")
                    .font(.headline)
                    .padding()

                GeometryReader { geometry in
                    VStack(spacing: 0) {
                        ForEach(0..<2, id: \.self) { offset in
                            let index = currentIndex + offset
                            if index < photos.count {
                                Image(uiImage: photos[index]) // Отображение выбранных фотографий
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: geometry.size.width, height: geometry.size.height / 2)
                                    .background(index == currentIndex ? topPhotoColor : bottomPhotoColor) // Применяем цвет подсветки
                                    .offset(y: index == currentIndex ? -swipeOffset : swipeOffset) // Верхняя фото всегда вверх, нижняя всегда вниз
                                    .gesture(
                                        DragGesture()
                                            .onEnded { value in
                                                handleSwipe(value: value, index: index)
                                            }
                                    )
                            }
                        }
                    }
                }

                HStack {
                    Button("Пропустить") {
                        skipPhoto()
                    }
                    .padding()
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(10)
                }
            } else {
                // Updated summary view: show counts instead of lists.
                VStack {
                    Text("Результаты")
                        .font(.title)
                        .padding()
                    
                    Text("Сохранено: \(savedPhotos.count)")
                        .font(.headline)
                        .padding(.top, 8)
                    
                    Text("Удалено: \(removedPhotos.count)")
                        .font(.headline)
                        .padding(.top, 4)
                    
                    Button("Выбрать другую дату") {
                        // Reset state to allow a new date selection
                        photos.removeAll()
                        photoAssets.removeAll()
                        savedPhotos.removeAll()
                        removedPhotos.removeAll()
                        currentIndex = 0
                        allAssets = nil
                    }
                    .padding()
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(10)
                }
                .padding()
            }
        }
        .padding()
        .onAppear {
            if #available(iOS 14, *) {
                PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                    switch status {
                    case .authorized, .limited:
                        print("Photo library access granted.")
                        DispatchQueue.main.async {
                            countPhotosByDate()  // New: fetch the correct count on launch
                        }
                    case .denied, .restricted:
                        print("[ERROR] Photo library access denied or restricted.")
                    case .notDetermined:
                        print("[ERROR] Photo library access not determined.")
                    @unknown default:
                        print("[ERROR] Unknown photo library access status.")
                    }
                }
            } else {
                PHPhotoLibrary.requestAuthorization { status in
                    switch status {
                    case .authorized:
                        print("Photo library access authorized.")
                        DispatchQueue.main.async {
                            countPhotosByDate()  // New: fetch the correct count on launch
                        }
                    case .denied, .restricted:
                        print("[ERROR] Photo library access denied or restricted.")
                    case .notDetermined:
                        print("[ERROR] Photo library access not determined.")
                    @unknown default:
                        print("[ERROR] Unknown photo library access status.")
                    }
                }
            }
        }
    }

    // New function to load photos in batches.
    private func fetchPhotos() {
        if allAssets == nil {
            allAssets = PHAsset.fetchAssets(with: .image, options: nil)
        }
        loadMorePhotos()
    }
    
    private func loadMorePhotos() {
        guard let allAssets = allAssets else { return }
        let startIndex = photoAssets.count
        let endIndex = min(startIndex + fetchBatchSize, allAssets.count)
        let manager = PHCachingImageManager()
        for index in startIndex..<endIndex {
            let asset = allAssets.object(at: index)
            photoAssets.append(asset)
            let options = PHImageRequestOptions()
            options.isSynchronous = true
            manager.requestImage(for: asset,
                                 targetSize: CGSize(width: 300, height: 300),
                                 contentMode: .aspectFill,
                                 options: options) { image, _ in
                if let image = image {
                    photos.append(image)
                    print("Loaded photo. Total photos: \(photos.count), Total assets: \(photoAssets.count)")
                }
            }
        }
    }

    private func fetchPhotosByDate() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "creationDate >= %@ AND creationDate < %@", startOfDay as NSDate, endOfDay as NSDate)
        let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        allAssets = assets
        // Reset any previously loaded photos.
        photos.removeAll()
        photoAssets.removeAll()
        currentIndex = 0
        let manager = PHCachingImageManager()
        assets.enumerateObjects { asset, _, _ in
            photoAssets.append(asset)
            let options = PHImageRequestOptions()
            options.isSynchronous = true
            manager.requestImage(for: asset,
                                 targetSize: CGSize(width: 300, height: 300),
                                 contentMode: .aspectFill,
                                 options: options) { image, _ in
                if let image = image {
                    photos.append(image)
                    print("Loaded photo. Total photos: \(photos.count), Total assets: \(photoAssets.count)")
                }
            }
        }
    }

    private func countPhotosByDate() {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "creationDate >= %@ AND creationDate < %@", startOfDay as NSDate, endOfDay as NSDate)
        let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        photoCountForDate = assets.count
    }

    // Modify deletePhoto to take a parameter whether to remove from arrays and add a completion:
    private func deletePhoto(at index: Int, removeFromArray: Bool = true, completion: @escaping (Bool) -> Void) {
        guard index < photoAssets.count, index < photos.count else {
            print("[ERROR] Index out of bounds for photoAssets or photos. Index: \(index), photoAssets Count: \(photoAssets.count), photos Count: \(photos.count)")
            completion(false)
            return
        }
        let asset = self.photoAssets[index]
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets([asset] as NSFastEnumeration)
        }) { success, error in
            if success {
                DispatchQueue.main.async {
                    if removeFromArray {
                        print("Photo deleted successfully.")
                        self.removedPhotos.append(self.photos[index])
                        self.photos.remove(at: index)
                        self.photoAssets.remove(at: index)
                    }
                    completion(true)
                }
            } else {
                DispatchQueue.main.async {
                    if let error = error {
                        print("[ERROR] Failed to delete photo: \(error.localizedDescription)")
                    } else {
                        print("[ERROR] Unknown error occurred while deleting photo.")
                    }
                    completion(false)
                }
            }
        }
    }

    // Modify handleSwipe as follows:
    private func handleSwipe(value: DragGesture.Value, index: Int) {
        guard !isAnimating else { return } // Block actions during animation

        if value.translation.height < -50 {
            // Swipe up: Keep top photo, delete bottom photo.
            withAnimation(.easeInOut(duration: 1.5)) {
                swipeOffset = UIScreen.main.bounds.height
                topPhotoColor = .green
                bottomPhotoColor = .red
                isAnimating = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                addToSaved(photo: photos[currentIndex])
                // Delete bottom photo at currentIndex+1 without auto-removal.
                deletePhoto(at: currentIndex + 1, removeFromArray: false) { success in
                    if success {
                        // Now remove both photos (the kept and the deleted one) from arrays.
                        self.photos.removeSubrange(currentIndex...(currentIndex+1))
                        self.photoAssets.removeSubrange(currentIndex...(currentIndex+1))
                    }
                    resetAnimation()
                }
            }
        } else if value.translation.height > 50 {
            // Swipe down: Keep bottom photo, delete top photo.
            withAnimation(.easeInOut(duration: 1.5)) {
                swipeOffset = UIScreen.main.bounds.height
                topPhotoColor = .red
                bottomPhotoColor = .green
                isAnimating = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                addToSaved(photo: photos[currentIndex+1])
                // Delete top photo at currentIndex without auto-removal.
                deletePhoto(at: currentIndex, removeFromArray: false) { success in
                    if success {
                        self.photos.removeSubrange(currentIndex...(currentIndex+1))
                        self.photoAssets.removeSubrange(currentIndex...(currentIndex+1))
                    }
                    resetAnimation()
                }
            }
        }
    }

    private func resetAnimation() {
        swipeOffset = 0
        topPhotoColor = .clear
        bottomPhotoColor = .clear
        isAnimating = false
    }

    private func moveToNextPair() {
        if currentIndex < photos.count - 2 {
            currentIndex += 2
        } else {
            currentIndex = photos.count
        }
        print("Current Index: \(currentIndex), Photos Count: \(photos.count)") // Отладка: индекс и количество фотографий
    }

    private func skipPhoto() {
        withAnimation(.easeInOut(duration: 1.5)) {
            swipeOffset = UIScreen.main.bounds.height
            topPhotoColor = .green
            bottomPhotoColor = .green
            isAnimating = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            savedPhotos.append(contentsOf: photos[currentIndex..<currentIndex + 2])
            moveToNextPair()
            resetAnimation()
        }
    }

    private func addToSaved(photo: UIImage) {
        if !savedPhotos.contains(photo) {
            savedPhotos.append(photo)
        }
    }

    // Add the helper function to compute the color:
    private func colorForCount() -> Color {
        let normalized = min(Double(photoCountForDate) / 100.0, 1.0)
        return Color(red: normalized, green: 1.0 - normalized, blue: 0.0)
    }
}

#Preview {
    ContentView()
}