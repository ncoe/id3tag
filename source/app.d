import dlangui;
import dlangui.dialogs.dialog;
import dlangui.dialogs.filedlg;
import dlangui.widgets.styles;

mixin APP_ENTRY_POINT;

// action codes
enum ActionEnum : int {
    NoAction = 1010000,
    FileNew,
    FileOpen,
    FileExit,
}

const Action ACTION_FILE_NEW  = new Action(ActionEnum.FileNew,  "MENU_FILE_NEW"c,  "document-new"c,   KeyCode.KEY_N, KeyFlag.Control);
const Action ACTION_FILE_OPEN = new Action(ActionEnum.FileOpen, "MENU_FILE_OPEN"c, "document-open"c,  KeyCode.KEY_O, KeyFlag.Control);
const Action ACTION_FILE_EXIT = new Action(ActionEnum.FileExit, "MENU_FILE_EXIT"c, "document-close"c, KeyCode.KEY_X, KeyFlag.Alt);

class MainFrame : AppFrame {
    this(string name) {
        super();

        _appName = name;
    }

    override protected void initialize() {
        // *** Start font override ***
        Theme theme = currentTheme;
        theme.fontFamily(FontFamily.SansSerif);
        theme.fontFace("Arial Unicode MS");
        Platform.instance.onThemeChanged();
        // *** End font override ***

        super.initialize();

        // Other initialization
    }

    /// create main menu
    MenuItem mainMenuItems;
    override protected MainMenu createMainMenu() {
        // File menu item
        mainMenuItems = new MenuItem();
        MenuItem fileItem = new MenuItem(new Action(1, "MENU_FILE"));
        fileItem.add(ACTION_FILE_NEW, ACTION_FILE_OPEN, ACTION_FILE_EXIT);
        mainMenuItems.add(fileItem);

        // The menu object itself
        MainMenu mainMenu = new MainMenu(mainMenuItems);
        return mainMenu;
    }

    /// create app toolbars
    // override protected ToolBarHost createToolbars() {
        // ToolBarHost res = new ToolBarHost();

        // ToolBar tb;
        // tb = res.getOrAddToolbar("Standard");
        // tb.addButtons(ACTION_FILE_NEW, ACTION_FILE_OPEN);

        // return res;
    // }

    bool onCanClose() {
        return true;
    }

    FileDialog createFileDialog(UIString caption, bool fileMustExist = true) {
        uint flags = DialogFlag.Modal | DialogFlag.Resizable;
        if (fileMustExist) {
            flags |= FileDialogFlag.FileMustExist;
        }
        FileDialog dlg = new FileDialog(caption, window, null, flags);
        dlg.filetypeIcons[".mp3"] = "MP3 files";
        dlg.path = "D:/Music"; //TODO store/load this from persistent properties
        return dlg;
    }

    /// override to handle specific actions
    override bool handleAction(const Action a) {
        if (a) {
            switch (a.id) {
                /////////////////////////////////
                case ActionEnum.FileOpen:
                    UIString caption;
                    caption = "Open MP3 File"d;
                    FileDialog dlg = createFileDialog(caption);
                    dlg.addFilter(FileFilterEntry(UIString.fromRaw("MP3 files"d), "*.mp3"));
                    dlg.addFilter(FileFilterEntry(UIString.fromRaw("All files"d), "*.*"));
                    dlg.dialogResult = delegate(Dialog dlg, const Action result) {
                        if (result.id == ACTION_OPEN.id) {
                            string filename = result.stringParam;

                            openSourceFile(filename);
                        }
                    };
                    dlg.show();
                    return true;
                /////////////////////////////////
                case ActionEnum.FileExit:
                    if (onCanClose()) {
                        window.close();
                    }
                    return true;
                /////////////////////////////////
                default:
                    return super.handleAction(a);
            }
        }
        return false;
    }

    /// create app body widget
    override protected Widget createBody() {
        VerticalLayout bodyWidget = new VerticalLayout();
        bodyWidget.layoutWidth = FILL_PARENT;
        bodyWidget.layoutHeight = FILL_PARENT;

        TabWidget tabs = new TabWidget("TABS");
        tabs.tabClose = delegate(string tabId) {
            tabs.removeTab(tabId);
        };

        //TODO: Make the following layout a specialized class
        {
            TableLayout layout = new TableLayout("id3v1");
            // layout.layoutWidth(FILL_PARENT);
            // layout.layoutWidth(WRAP_CONTENT);
            layout.backgroundColor("#EEEEEE");
            layout.colCount = 2;
            layout.padding = 5;

            // Row 1 - Title
            TextWidget titleLbl = new TextWidget("titleLbl", "Title"d);
            // titleLbl.minWidth = 70;
            layout.addChild(titleLbl);
            EditLine title = new EditLine("title", "<none>"d);
            title.minWidth = 250;
            title.enabled = false;
            layout.addChild(title);

            // Row 2 - Artist
            TextWidget artistLbl = new TextWidget("artistLbl", "Artist"d);
            layout.addChild(artistLbl);
            EditLine artist = new EditLine("artist", "<none>"d);
            artist.enabled = false;
            layout.addChild(artist);

            // Row 2 - Album
            TextWidget albumLbl = new TextWidget("albumLbl", "Album"d);
            layout.addChild(albumLbl);
            EditLine album = new EditLine("album", "<none>"d);
            album.enabled = false;
            layout.addChild(album);

            // Row 3 - Year
            TextWidget yearLbl = new TextWidget("yearLbl", "Year"d);
            layout.addChild(yearLbl);
            EditLine year = new EditLine("year", "<none>"d);
            year.enabled = false;
            layout.addChild(year);

            // Row 4 - Year
            TextWidget commentLbl = new TextWidget("commentLbl", "Comment"d);
            layout.addChild(commentLbl);
            EditLine comment = new EditLine("comment", "<none>"d);
            comment.enabled = false;
            layout.addChild(comment);

            // Row 5 - Track
            TextWidget trackLbl = new TextWidget("trackLbl", "Track"d);
            layout.addChild(trackLbl);
            EditLine track = new EditLine("track", "<none>"d);
            track.enabled = false;
            layout.addChild(track);

            // Row 6 - Track
            TextWidget genreLbl = new TextWidget("genreLbl", "Genre"d);
            layout.addChild(genreLbl);
            EditLine genre = new EditLine("genre", "<none>"d);
            genre.enabled = false;
            layout.addChild(genre);

            // Add the table
            tabs.addTab(layout, "ID3v1 info"d);
        }

        bodyWidget.addChild(tabs);
        return bodyWidget;
    }

    string _filename;
    void openSourceFile(string filename) {
        import std.file;
        import std.format;
        if (exists(filename)) {
            _filename = filename;
            window.windowCaption = toUTF32(_appName ~ " | " ~ filename);

            auto mp3file = cast(ubyte[]) read(filename);
            if (mp3file.length > 128) {
                auto id3v1 = mp3file[$-128..$];
                if (id3v1[0..3] == "TAG") {
                    // 3 bytes "TAG" only
                    int pos = 3;

                    auto tabWidget = window.mainWidget.childById("TABS");
                    auto tabLayout = tabWidget.childById("id3v1");

                    auto title  = tabLayout.childById("title");
                    title.text  = fixZeroPaddedString(id3v1[pos .. pos+30]);  // 30 byte title
                    pos += 30;

                    auto artist = tabLayout.childById("artist");
                    artist.text = fixZeroPaddedString(id3v1[pos .. pos+30]);  // 30 byte artist
                    pos += 30;

                    auto album  = tabLayout.childById("album");
                    album.text  = fixZeroPaddedString(id3v1[pos .. pos+30]);  // 30 byte album
                    pos += 30;

                    auto year  = tabLayout.childById("year");
                    year.text  = fixZeroPaddedString(id3v1[pos .. pos+4]);    // 4 byte year
                    pos += 4;

                    auto comment = tabLayout.childById("comment");
                    auto commentBytes = id3v1[pos .. pos+30];
                    comment.text = fixZeroPaddedString(commentBytes); // 30 byte comment
                    pos += 30;

                    auto track = tabLayout.childById("track");
                    if (commentBytes[$-2] == 0) {
                        track.text = to!dstring(commentBytes[$-1]); // 1 byte conditionally
                    } else {
                        track.text = "<none>"d;
                    }

                    auto genre = tabLayout.childById("genre");
                    genre.text = getGenre(id3v1[$-1]);

                    tabLayout.requestLayout;
                    setStatusLine("File loaded successfully");
                } else {
                    setStatusLine("No ID3v1 tag");
                }
            } else {
                setStatusLine("ERROR: Insufficient file length.");
            }

            window.invalidate;
        }
    }

    dstring fixZeroPaddedString(ubyte[] input) {
        for (int i=0; i<input.length; ++i) {
            if (input[i] == 0) {
                input.length = i;
                break;
            }
        }
        return toUTF32(cast(string) input);
    }

    dstring getGenre(ubyte genreByte) {
        switch(genreByte) {
            case 0: return "Blues"d;
            case 1: return "Classic Rock"d;
            case 2: return "Country"d;
            case 3: return "Dance"d;
            case 4: return "Disco"d;
            case 5: return "Funk"d;
            case 6: return "Grunge"d;
            case 7: return "Hip-Hop"d;
            case 8: return "Jazz"d;
            case 9: return "Metal"d;
            case 10: return "New Age"d;
            case 11: return "Oldies"d;
            case 12: return "Other"d;
            case 13: return "Pop"d;
            case 14: return "R&B"d;
            case 15: return "Rap"d;
            case 16: return "Reggae"d;
            case 17: return "Rock"d;
            case 18: return "Techno"d;
            case 19: return "Industrial"d;
            case 20: return "Alternative"d;
            case 21: return "Ska"d;
            case 22: return "Death Metal"d;
            case 23: return "Pranks"d;
            case 24: return "Soundtrack"d;
            case 25: return "Euro-Techno"d;
            case 26: return "Ambient"d;
            case 27: return "Trip-Hop"d;
            case 28: return "Vocal"d;
            case 29: return "Jazz+Funk"d;
            case 30: return "Fusion"d;
            case 31: return "Trance"d;
            case 32: return "Classical"d;
            case 33: return "Instrumental"d;
            case 34: return "Acid"d;
            case 35: return "House"d;
            case 36: return "Game"d;
            case 37: return "Sound Clip"d;
            case 38: return "Gospel"d;
            case 39: return "Noise"d;
            case 40: return "AlternRock"d;
            case 41: return "Bass"d;
            case 42: return "Soul"d;
            case 43: return "Punk"d;
            case 44: return "Space"d;
            case 45: return "Meditative"d;
            case 46: return "Instrumental Pop"d;
            case 47: return "Instrumental Rock"d;
            case 48: return "Ethnic"d;
            case 49: return "Gothic"d;
            case 50: return "Darkwave"d;
            case 51: return "Techno-Industrial"d;
            case 52: return "Electronic"d;
            case 53: return "Pop-Folk"d;
            case 54: return "Eurodance"d;
            case 55: return "Dream"d;
            case 56: return "Southern Rock"d;
            case 57: return "Comedy"d;
            case 58: return "Cult"d;
            case 59: return "Gangsta"d;
            case 60: return "Top 40"d;
            case 61: return "Christian Rap"d;
            case 62: return "Pop/Funk"d;
            case 63: return "Jungle"d;
            case 64: return "Native American"d;
            case 65: return "Cabaret"d;
            case 66: return "New Wave"d;
            case 67: return "Psychadelic"d;
            case 68: return "Rave"d;
            case 69: return "Showtunes"d;
            case 70: return "Trailer"d;
            case 71: return "Lo-Fi"d;
            case 72: return "Tribal"d;
            case 73: return "Acid Punk"d;
            case 74: return "Acid Jazz"d;
            case 75: return "Polka"d;
            case 76: return "Retro"d;
            case 77: return "Musical"d;
            case 78: return "Rock & Roll"d;
            case 79: return "Hard Rock"d;
            //-------------------------
            // Winamp extensions
            //-------------------------
            case 80: return "Folk"d;
            case 81: return "Folk-Rock"d;
            case 82: return "National Folk"d;
            case 83: return "Swing"d;
            case 84: return "Fast Fusion"d;
            case 85: return "Bebob"d;
            case 86: return "Latin"d;
            case 87: return "Revival"d;
            case 88: return "Celtic"d;
            case 89: return "Bluegrass"d;
            case 90: return "Avantgarde"d;
            case 91: return "Gothic Rock"d;
            case 92: return "Progressive Rock"d;
            case 93: return "Psychadelic Rock"d;
            case 94: return "Symphonic Rock"d;
            case 95: return "Slow Rock"d;
            case 96: return "Big Band"d;
            case 97: return "Chorus"d;
            case 98: return "Easy Listening"d;
            case 99: return "Acoustic"d;
            case 100: return "Humour"d;
            case 101: return "Speech"d;
            case 102: return "Chanson"d;
            case 103: return "Opera"d;
            case 104: return "Chamber Music"d;
            case 105: return "Sonata"d;
            case 106: return "Symphony"d;
            case 107: return "Booty Bass"d;
            case 108: return "Primus"d;
            case 109: return "Porn Groove"d;
            case 110: return "Satire"d;
            case 111: return "Slow Jam"d;
            case 112: return "Club"d;
            case 113: return "Tango"d;
            case 114: return "Samba"d;
            case 115: return "Folklore"d;
            case 116: return "Ballad"d;
            case 117: return "Power Ballad"d;
            case 118: return "Rhythmic Soul"d;
            case 119: return "Freestyle"d;
            case 120: return "Duet"d;
            case 121: return "Punk Rock"d;
            case 122: return "Drum Solo"d;
            case 123: return "A capella"d;
            case 124: return "Euro-House"d;
            case 125: return "Dance Hall"d;

            default:
                return to!dstring(genreByte);
        }
    }

    void setStatusLine(dstring text) {
        if (statusLine) {
            statusLine.setStatusText(text);
        }
    }

    // void saveSourceFile(string filename) {
        // if (filename.length == 0)
            // filename = _filename;
        // import std.file;
        // _filename = filename;
        // window.windowCaption = toUTF32(filename);
        // _editor.save(filename);
    // }
}

/// entry point for dlangui based application
extern (C)
int UIAppMain(string[] args) {
    // embed non-standard resources listed in views/resources.list into executable
    embeddedResourceList.addResources(embedResourcesFromList!("resources.list")());

    // override the default window icon
    Platform.instance.defaultWindowIcon = "mp3-file-icon-sm";

    /// set font gamma (1.0 is neutral, < 1.0 makes glyphs lighter, >1.0 makes glyphs bolder)
    FontManager.fontGamma = 0.8;
    FontManager.hintingMode = HintingMode.Normal;

    //TODO reconsider themes once enough content is in place
    // load theme from file "theme_custom.xml"
    // Platform.instance.uiTheme = "theme_custom";

    // create window
    //TODO: remove extra characters used to check font
    Window window = Platform.instance.createWindow("ID3 Tag Editor | こんにちわ"d, null, WindowFlag.Resizable, 700, 470);

    // place the frame in the window
    window.mainWidget = new MainFrame("ID3 Tag Editor");

    // show window
    window.show();

    // run message loop
    return Platform.instance.enterMessageLoop();
}
