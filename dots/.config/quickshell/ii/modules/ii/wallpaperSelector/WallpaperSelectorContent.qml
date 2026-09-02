import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell
import Quickshell.Io

// Full-screen revolving wallpaper selector.
//
// Two departures from the stock version:
//   * it is an overlay, not a panel -- a dimmed full-screen scrim with the
//     carousel floating on it, instead of a 1200x690 card hanging off the bar
//   * the grid is a PathView riding a shallow arc: upright cards, centre one
//     full size, neighbours shrinking and fading out toward the edges
//
// Thumbnails are generated on demand per visible card rather than relying on a
// batch pass over the folder, because that batch does not reliably produce the
// larger sizes these cards ask for, and a card with no thumbnail is just an
// empty rectangle.
Item {
    id: root

    property bool monitorIsFocused: true
    property bool useDarkMode: Appearance.m3colors.darkmode
    readonly property real previewCellAspectRatio: 4 / 3

    // Two tracks on one carousel. Wallpapers browse the filesystem; rices are
    // whatever `rice list --json` reports. Applying a rice always lands on
    // that rice's own wallpaper, which is why they are separate tracks rather
    // than rices being a folder of images.
    property bool ricesMode: false

    function setMode(rices) {
        if (root.ricesMode === rices)
            return;
        root.ricesMode = rices;
        if (rices) {
            Rices.reload();
            carousel.currentIndex = Rices.indexOfCurrent();
        } else {
            carousel.currentIndex = 0;
        }
    }

    function activateCurrent() {
        if (carousel.count === 0)
            return;
        if (root.ricesMode) {
            const rice = Rices.rices[carousel.currentIndex];
            if (rice)
                Rices.apply(rice.riceName);
            GlobalStates.wallpaperSelectorOpen = false;
            return;
        }
        root.selectWallpaperPath(Wallpapers.folderModel.get(carousel.currentIndex, "filePath"));
    }

    function handleFilePasting(event) {
        const currentClipboardEntry = Cliphist.entries[0];
        if (/^\d+\tfile:\/\/\S+/.test(currentClipboardEntry)) {
            const url = StringUtils.cleanCliphistEntry(currentClipboardEntry);
            Wallpapers.setDirectory(FileUtils.trimFileProtocol(decodeURIComponent(url)));
            event.accepted = true;
        } else {
            event.accepted = false; // No image, let text pasting proceed
        }
    }

    function selectWallpaperPath(filePath) {
        if (filePath && filePath.length > 0) {
            Wallpapers.select(filePath, root.useDarkMode);
            filterField.text = "";
        }
    }

    focus: true

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            GlobalStates.wallpaperSelectorOpen = false;
            event.accepted = true;
        } else if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_V) { // Intercept Ctrl+V to handle "paste to go to" in pickers
            root.handleFilePasting(event);
        } else if (event.modifiers & Qt.AltModifier && event.key === Qt.Key_Up) {
            Wallpapers.navigateUp();
            event.accepted = true;
        } else if (event.modifiers & Qt.AltModifier && event.key === Qt.Key_Left) {
            Wallpapers.navigateBack();
            event.accepted = true;
        } else if (event.modifiers & Qt.AltModifier && event.key === Qt.Key_Right) {
            Wallpapers.navigateForward();
            event.accepted = true;
        } else if (event.key === Qt.Key_Left) {
            carousel.moveSelection(-1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Right) {
            carousel.moveSelection(1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Up || event.key === Qt.Key_PageUp) {
            carousel.moveSelection(-carousel.pageStep);
            event.accepted = true;
        } else if (event.key === Qt.Key_Down || event.key === Qt.Key_PageDown) {
            carousel.moveSelection(carousel.pageStep);
            event.accepted = true;
        } else if (event.key === Qt.Key_Home) {
            carousel.jumpTo(0);
            event.accepted = true;
        } else if (event.key === Qt.Key_End) {
            carousel.jumpTo(carousel.count - 1);
            event.accepted = true;
        } else if (event.key === Qt.Key_Tab) {
            root.setMode(!root.ricesMode);
            event.accepted = true;
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.activateCurrent();
            event.accepted = true;
        } else if (event.key === Qt.Key_Backspace) {
            if (filterField.text.length > 0) {
                filterField.text = filterField.text.substring(0, filterField.text.length - 1);
            }
            filterField.forceActiveFocus();
            event.accepted = true;
        } else if (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_L) {
            addressBar.focusBreadcrumb();
            event.accepted = true;
        } else if (event.key === Qt.Key_Slash) {
            filterField.forceActiveFocus();
            event.accepted = true;
        } else {
            if (event.text.length > 0) {
                filterField.text += event.text;
                filterField.cursorPosition = filterField.text.length;
                filterField.forceActiveFocus();
            }
            event.accepted = true;
        }
    }

    // ------------------------------------------------------------------
    // Scrim. Clicking it (or a back/forward mouse button) is how you get out.
    // ------------------------------------------------------------------
    Rectangle {
        id: scrim
        anchors.fill: parent
        // Appearance.colors.colScrim is only 50% alpha, and the dots'' layer rule
        // skips blurring anything under 0.79 alpha, so at that value the desktop
        // stayed sharp and fully readable behind the carousel -- which is what
        // made it look like leftover chrome rather than an overlay. custom/rules.lua
        // lowers ignore_alpha for this namespace so this gets blurred too.
        color: ColorUtils.transparentize(Appearance.m3colors.m3scrim, 0.35)
        opacity: 0
        Component.onCompleted: opacity = 1
        Behavior on opacity {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.BackButton | Qt.ForwardButton
            onPressed: event => {
                if (event.button === Qt.BackButton) {
                    Wallpapers.navigateBack();
                } else if (event.button === Qt.ForwardButton) {
                    Wallpapers.navigateForward();
                } else {
                    GlobalStates.wallpaperSelectorOpen = false;
                }
            }
        }
    }

    // ------------------------------------------------------------------
    // Top: where you are, and where you can jump to
    // ------------------------------------------------------------------
    ColumnLayout {
        id: header
        anchors {
            top: parent.top
            horizontalCenter: parent.horizontalCenter
            topMargin: Appearance.sizes.barHeight + 20
        }
        width: Math.min(root.width - 80, 900)
        spacing: 10

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            color: Appearance.colors.colOnLayer0
            font {
                pixelSize: Appearance.font.pixelSize.huge
                weight: Font.Medium
            }
            text: root.ricesMode ? Translation.tr("Pick a rice") : Translation.tr("Pick a wallpaper")
        }

        // Track switch. Built from two RippleButtons in a pill rather than
        // ToolbarTabBar, which throws a currentIndex binding loop in this shell.
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: trackRow.implicitWidth + 8
            implicitHeight: trackRow.implicitHeight + 8
            radius: Appearance.rounding.full
            color: Appearance.colors.colLayer1

            RowLayout {
                id: trackRow
                anchors.centerIn: parent
                spacing: 4

                Repeater {
                    model: [
                        {
                            label: Translation.tr("Wallpapers"),
                            icon: "wallpaper",
                            rices: false
                        },
                        {
                            label: Translation.tr("Rices"),
                            icon: "palette",
                            rices: true
                        },
                    ]
                    delegate: RippleButton {
                        id: trackButton
                        required property var modelData
                        toggled: root.ricesMode === modelData.rices
                        onClicked: root.setMode(trackButton.modelData.rices)
                        colBackgroundToggled: Appearance.colors.colSecondaryContainer
                        colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
                        colRippleToggled: Appearance.colors.colSecondaryContainerActive
                        buttonRadius: Appearance.rounding.full
                        implicitHeight: 34
                        implicitWidth: trackButtonRow.implicitWidth + 30

                        contentItem: RowLayout {
                            id: trackButtonRow
                            spacing: 6
                            MaterialSymbol {
                                color: trackButton.toggled ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer1
                                iconSize: Appearance.font.pixelSize.larger
                                text: trackButton.modelData.icon
                                fill: trackButton.toggled ? 1 : 0
                            }
                            StyledText {
                                color: trackButton.toggled ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer1
                                text: trackButton.modelData.label
                            }
                        }
                    }
                }
            }
        }

        AddressBar {
            id: addressBar
            visible: !root.ricesMode
            Layout.fillWidth: true
            directory: Wallpapers.effectiveDirectory
            onNavigateToDirectory: path => {
                Wallpapers.setDirectory(path.length == 0 ? "/" : path);
            }
            radius: Appearance.rounding.full
        }

        // Quick directories, as a chip row rather than the old sidebar -- a
        // vertical list down the left of a full screen would be mostly empty.
        // Quick directories are filesystem navigation, meaningless on the
        // rices track.
        Flow {
            visible: !root.ricesMode
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            spacing: 6

            Repeater {
                model: [
                    {
                        icon: "home",
                        name: "Home",
                        path: Directories.home
                    },
                    {
                        icon: "docs",
                        name: "Documents",
                        path: Directories.documents
                    },
                    {
                        icon: "download",
                        name: "Downloads",
                        path: Directories.downloads
                    },
                    {
                        icon: "image",
                        name: "Pictures",
                        path: Directories.pictures
                    },
                    {
                        icon: "movie",
                        name: "Videos",
                        path: Directories.videos
                    },
                    {
                        icon: "wallpaper",
                        name: "Wallpapers",
                        path: `${Directories.pictures}/Wallpapers`
                    },
                    ...(Config.options.policies.weeb === 1 ? [
                            {
                                icon: "favorite",
                                name: "Homework",
                                path: `${Directories.pictures}/homework`
                            }
                        ] : []),]

                delegate: RippleButton {
                    id: quickDirButton
                    required property var modelData

                    onClicked: Wallpapers.setDirectory(quickDirButton.modelData.path)
                    toggled: Wallpapers.directory === Qt.resolvedUrl(modelData.path)
                    colBackgroundToggled: Appearance.colors.colSecondaryContainer
                    colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
                    colRippleToggled: Appearance.colors.colSecondaryContainerActive
                    buttonRadius: Appearance.rounding.full
                    implicitHeight: 36
                    implicitWidth: quickDirRow.implicitWidth + 28

                    contentItem: RowLayout {
                        id: quickDirRow
                        spacing: 6
                        MaterialSymbol {
                            color: quickDirButton.toggled ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer1
                            iconSize: Appearance.font.pixelSize.larger
                            text: quickDirButton.modelData.icon
                            fill: quickDirButton.toggled ? 1 : 0
                        }
                        StyledText {
                            color: quickDirButton.toggled ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer1
                            text: quickDirButton.modelData.name
                        }
                    }
                }
            }
        }
    }

    // ------------------------------------------------------------------
    // Middle: the carousel
    // ------------------------------------------------------------------
    Item {
        id: carouselRegion
        anchors {
            top: header.bottom
            bottom: footer.top
            left: parent.left
            right: parent.right
            topMargin: 8
            bottomMargin: 8
        }

        StyledIndeterminateProgressBar {
            id: indeterminateProgressBar
            visible: Wallpapers.thumbnailGenerationRunning && value == 0
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                leftMargin: 60
                rightMargin: 60
            }
        }

        StyledProgressBar {
            visible: Wallpapers.thumbnailGenerationRunning && value > 0
            value: Wallpapers.thumbnailGenerationProgress
            anchors.fill: indeterminateProgressBar
        }

        PathView {
            id: carousel
            visible: count > 0
            anchors.fill: parent

            model: root.ricesMode ? Rices.rices : Wallpapers.folderModel
            onModelChanged: currentIndex = root.ricesMode ? Rices.indexOfCurrent() : 0

            // Capped at 540 so the image area inside a card (540 minus 28px of
            // margin and padding) stays just under 512, keeping thumbnails in
            // the x-large bucket. One notch wider and every card needs a
            // 1024px thumbnail built on the fly while you spin.
            readonly property real cardWidth: Math.max(280, Math.min(540, root.width * 0.30))
            readonly property real cardHeight: cardWidth / root.previewCellAspectRatio
            readonly property int pageStep: 5

            // Size bucket for the thumbnails, from the real drawn size of the
            // image area inside a card.
            readonly property real imageInset: (Appearance.sizes.wallpaperSelectorItemMargins + Appearance.sizes.wallpaperSelectorItemPadding) * 2
            readonly property string thumbSize: Images.thumbnailSizeNameForDimensions(cardWidth - imageInset, cardHeight - imageInset)

            // Arc geometry. The ends hang `arcDip` below the apex; cards never
            // rotate, so thumbnails are never sheared.
            readonly property real apexY: height * 0.48
            readonly property real arcDip: Math.min(64, height * 0.10)
            readonly property real overhang: cardWidth * 0.4

            readonly property real edgeScale: 0.55
            readonly property real edgeOpacity: 0.30

            pathItemCount: 5
            preferredHighlightBegin: 0.5
            preferredHighlightEnd: 0.5
            highlightRangeMode: PathView.StrictlyEnforceRange
            snapMode: PathView.SnapToItem
            highlightMoveDuration: Appearance.animation.elementMoveFast.duration
            interactive: true
            cacheItemCount: 4

            // A PathView is a loop -- dragging already wraps past the last item
            // back to the first. Clamping here made the wheel and arrow keys
            // behave differently from the drag: dead at both ends, and stuck at
            // index 0 when scrolling back. Wrap instead, using PathView's own
            // increment/decrement for single steps so the shortest-path
            // animation is picked when crossing the seam.
            function moveSelection(delta) {
                if (count === 0)
                    return;
                if (delta === 1) {
                    incrementCurrentIndex();
                    return;
                }
                if (delta === -1) {
                    decrementCurrentIndex();
                    return;
                }
                currentIndex = ((currentIndex + delta) % count + count) % count;
            }

            // Home/End are absolute, so these clamp rather than wrap.
            function jumpTo(index) {
                if (count === 0)
                    return;
                currentIndex = Math.max(0, Math.min(count - 1, index));
            }

            function activateCurrent() {
                root.activateCurrent();
            }

            // Two mirrored quadratic curves meeting at the apex. Each control
            // point sits level with the apex, which makes the tangent there
            // horizontal, so the centre card is flat rather than tipping over
            // the top of the curve.
            path: Path {
                startX: -carousel.overhang
                startY: carousel.apexY + carousel.arcDip

                PathAttribute {
                    name: "itemScale"
                    value: carousel.edgeScale
                }
                PathAttribute {
                    name: "itemOpacity"
                    value: carousel.edgeOpacity
                }
                PathAttribute {
                    name: "itemZ"
                    value: 0
                }

                PathQuad {
                    x: carousel.width / 2
                    y: carousel.apexY
                    controlX: carousel.width / 4
                    controlY: carousel.apexY
                }

                PathAttribute {
                    name: "itemScale"
                    value: 1.0
                }
                PathAttribute {
                    name: "itemOpacity"
                    value: 1.0
                }
                PathAttribute {
                    name: "itemZ"
                    value: 10
                }

                PathQuad {
                    x: carousel.width + carousel.overhang
                    y: carousel.apexY + carousel.arcDip
                    controlX: carousel.width * 0.75
                    controlY: carousel.apexY
                }

                PathAttribute {
                    name: "itemScale"
                    value: carousel.edgeScale
                }
                PathAttribute {
                    name: "itemOpacity"
                    value: carousel.edgeOpacity
                }
                PathAttribute {
                    name: "itemZ"
                    value: 0
                }
            }

            // A WheelHandler rather than a MouseArea, so scrolling does not
            // swallow clicks on the cards underneath.
            WheelHandler {
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: event => {
                    if (event.angleDelta.y < 0 || event.angleDelta.x > 0)
                        carousel.moveSelection(1);
                    else if (event.angleDelta.y > 0 || event.angleDelta.x < 0)
                        carousel.moveSelection(-1);
                }
            }

            delegate: Item {
                id: card
                required property var modelData
                required property int index

                readonly property bool isCurrent: index === carousel.currentIndex
                readonly property bool isApplied: root.ricesMode ? (modelData.riceName === Rices.currentRice) : (modelData.filePath === Config.options.background.wallpaperPath)

                width: carousel.cardWidth
                height: carousel.cardHeight

                z: PathView.itemZ ?? 0
                scale: PathView.itemScale ?? 1
                opacity: PathView.itemOpacity ?? 1
                visible: PathView.onPath

                WallpaperDirectoryItem {
                    anchors.fill: parent
                    fileModelData: card.modelData

                    // Build the thumbnail if it is missing, at exactly the size
                    // this view looks for. Only the visible cards ever ask.
                    generateThumbnail: true
                    thumbnailSizeNameOverride: carousel.thumbSize
                    showLabel: false

                    // A rice entry is named after the rice, not the image file,
                    // so the extension check that decides 'is this a picture?'
                    // says no and every card falls back to a generic file icon.
                    // On this track the path is always an image.
                    useThumbnail: root.ricesMode || Images.isValidImageByName(card.modelData.fileName)

                    colBackground: (card.isCurrent || containsMouse) ? Appearance.colors.colPrimary : card.isApplied ? Appearance.colors.colSecondaryContainer : ColorUtils.transparentize(Appearance.colors.colPrimaryContainer)
                    colText: (card.isCurrent || containsMouse) ? Appearance.colors.colOnPrimary : card.isApplied ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer0

                    // First click on an off-centre card brings it to the middle;
                    // clicking the centre card applies it. Otherwise a mistimed
                    // click on a half-faded edge card sets a wallpaper you never
                    // got a proper look at.
                    onActivated: {
                        if (!card.isCurrent) {
                            carousel.currentIndex = card.index;
                            return;
                        }
                        root.activateCurrent();
                    }
                }
            }
        }

        StyledText {
            anchors.centerIn: parent
            visible: carousel.count === 0
            color: Appearance.colors.colSubtext
            font.pixelSize: Appearance.font.pixelSize.normal
            text: {
                if (root.ricesMode)
                    return Rices.lastError.length > 0 ? Rices.lastError : Translation.tr("No rices found. Create one with:  rice save <name>");
                return Wallpapers.searchQuery.length > 0 ? Translation.tr("Nothing matches that search") : Translation.tr("No images in this folder");
            }
        }
    }

    // ------------------------------------------------------------------
    // Bottom: what is selected, and the controls
    // ------------------------------------------------------------------
    ColumnLayout {
        id: footer
        anchors {
            bottom: parent.bottom
            horizontalCenter: parent.horizontalCenter
            bottomMargin: 40
        }
        width: Math.min(root.width - 80, 900)
        spacing: 4

        // The card labels are gone in favour of one big name here, so the
        // thumbnails stay clean and the name is readable from across the room.
        StyledText {
            Layout.alignment: Qt.AlignHCenter
            Layout.maximumWidth: parent.width
            visible: carousel.count > 0
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideMiddle
            color: Appearance.colors.colOnLayer0
            font {
                pixelSize: Appearance.font.pixelSize.large
                weight: Font.Medium
            }
            text: {
                if (carousel.count === 0)
                    return "";
                if (root.ricesMode)
                    return Rices.rices[carousel.currentIndex]?.label ?? "";
                return Wallpapers.folderModel.get(carousel.currentIndex, "fileName") ?? "";
            }
        }

        // On a grid you can see the whole folder; on a carousel you cannot.
        StyledText {
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: 10
            visible: carousel.count > 0
            color: Appearance.colors.colSubtext
            font.pixelSize: Appearance.font.pixelSize.smaller
            text: `${carousel.currentIndex + 1} / ${carousel.count}`
        }

        Row {
            Layout.alignment: Qt.AlignHCenter
            spacing: 6

            // Every control in here acts on the wallpaper folder -- system file
            // picker, random-from-folder, light/dark, search. None of them mean
            // anything while browsing rices, so the whole bar steps aside and
            // leaves just the close button.
            Toolbar {
                visible: !root.ricesMode
                IconToolbarButton {
                    implicitWidth: height
                    onClicked: {
                        Wallpapers.openFallbackPicker(root.useDarkMode);
                        GlobalStates.wallpaperSelectorOpen = false;
                    }
                    altAction: () => {
                        Wallpapers.openFallbackPicker(root.useDarkMode);
                        GlobalStates.wallpaperSelectorOpen = false;
                        Config.options.wallpaperSelector.useSystemFileDialog = true;
                    }
                    text: "open_in_new"
                    StyledToolTip {
                        text: Translation.tr("Use the system file picker instead\nRight-click to make this the default behavior")
                    }
                }

                IconToolbarButton {
                    implicitWidth: height
                    onClicked: {
                        Wallpapers.randomFromCurrentFolder();
                    }
                    text: "ifl"
                    StyledToolTip {
                        text: Translation.tr("Pick random from this folder")
                    }
                }

                IconToolbarButton {
                    implicitWidth: height
                    onClicked: root.useDarkMode = !root.useDarkMode
                    text: root.useDarkMode ? "dark_mode" : "light_mode"
                    StyledToolTip {
                        text: Translation.tr("Click to toggle light/dark mode\n(applied when wallpaper is chosen)")
                    }
                }

                ToolbarTextField {
                    id: filterField
                    visible: !root.ricesMode
                    placeholderText: focus ? Translation.tr("Search wallpapers") : Translation.tr("Hit \"/\" to search")

                    clip: true
                    font.pixelSize: Appearance.font.pixelSize.small

                    onTextChanged: {
                        Wallpapers.searchQuery = text;
                    }

                    Keys.onPressed: event => {
                        if ((event.modifiers & Qt.ControlModifier) && event.key === Qt.Key_V) { // Intercept Ctrl+V to handle "paste to go to" in pickers
                            root.handleFilePasting(event);
                            return;
                        } else if (text.length !== 0) {
                            if (event.key === Qt.Key_Down) {
                                carousel.moveSelection(carousel.pageStep);
                                event.accepted = true;
                                return;
                            }
                            if (event.key === Qt.Key_Up) {
                                carousel.moveSelection(-carousel.pageStep);
                                event.accepted = true;
                                return;
                            }
                        }
                        event.accepted = false;
                    }
                }
            }

            ToolbarPairedFab {
                iconText: "close"
                onClicked: GlobalStates.wallpaperSelectorOpen = false
                StyledToolTip {
                    text: Translation.tr("Cancel wallpaper selection")
                }
            }
        }
    }

    Connections {
        target: GlobalStates
        function onWallpaperSelectorOpenChanged() {
            if (GlobalStates.wallpaperSelectorOpen && root.monitorIsFocused) {
                filterField.forceActiveFocus();
            }
        }
    }

    Connections {
        target: Wallpapers
        function onChanged() {
            GlobalStates.wallpaperSelectorOpen = false;
        }
    }
}
