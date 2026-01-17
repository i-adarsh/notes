I cannot directly generate a downloadable `.dmg` file as I am an AI text model. However, I can provide you with the **complete Python source code** and a step-by-step guide to building this tool yourself in about 10 minutes.

This custom tool will mimic Glaido's functionality: **Global Hotkey**  **Record Voice**  **Convert to Text**  **Type at Cursor**.

### Option 1: The "Zero-Code" Native Solution

Before building a custom tool, note that macOS has this feature built-in.

* **Try this:** Go to any text field and press **F5** (or double-press the **Control** key).
* **Result:** macOS Dictation starts and types whatever you say at your cursor.
* **Why build your own?** The native version sometimes times out or lacks "AI" correction. Building your own allows you to swap in powerful AI models (like OpenAI Whisper) later.

---

### Option 2: The "Build Your Own" Solution (Python)

We will create a script that listens for a hotkey (e.g., `F8`), records your voice, and types the text.

#### **Step 1: Install Prerequisites**

You will need Python installed. Open your **Terminal** and run these commands to install the necessary libraries for audio recording and keyboard control.

```bash
# Install system helper for audio (requires Homebrew)
brew install portaudio

# Install Python libraries
pip install SpeechRecognition pyaudio pynput pyautogui sounddevice

```

#### **Step 2: The Source Code**

Save the following code into a file named `glaido_clone.py`.

```python
import speech_recognition as sr
from pynput import keyboard
import pyautogui
import sounddevice as sd
import soundfile as sf
import numpy as np
import tempfile
import os
import sys

# --- CONFIGURATION ---
HOTKEY = keyboard.Key.f8  # The key to Start/Stop recording
# ---------------------

print(f"🎤 Glaido Clone is running...")
print(f"👉 Press [{HOTKEY.name}] to toggle recording.")
print(f"👉 Press [Esc] to quit.")

recorder = sr.Recognizer()
is_recording = False

def record_and_type():
    """Records audio from the microphone and types the text."""
    global is_recording
    
    # Use a temporary file to store the audio
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as temp_audio:
        temp_filename = temp_audio.name

    try:
        # 1. Record Audio
        print("\n🔴 Recording... (Speak now)")
        # Record at 44100 Hz
        fs = 44100 
        myrecording = []
        
        # Simple recording loop that stops when we toggle the flag back
        # Note: For simplicity in this script, we record for a fixed duration 
        # or until silence. Here we use the speech_recognition library's native listener
        # which is smarter at detecting silence.
        
        with sr.Microphone() as source:
            recorder.adjust_for_ambient_noise(source, duration=0.5)
            # Listen until silence is detected
            audio_data = recorder.listen(source, timeout=5, phrase_time_limit=15)
            
        print("🟡 Processing...")

        # 2. Convert Voice to Text (Using Google's free API)
        # You can swap this with 'recorder.recognize_whisper()' if you install openai-whisper
        text = recorder.recognize_google(audio_data)
        
        print(f"✅ Recognized: {text}")

        # 3. Type text at cursor
        # We add a small space before if needed, or capitalization logic here
        pyautogui.write(f"{text} ")

    except sr.WaitTimeoutError:
        print("❌ No speech detected.")
    except sr.UnknownValueError:
        print("❌ Could not understand audio.")
    except Exception as e:
        print(f"❌ Error: {e}")
    finally:
        # Cleanup
        if os.path.exists(temp_filename):
            os.remove(temp_filename)

def on_press(key):
    """Handler for key presses."""
    if key == HOTKEY:
        # Trigger the recording function
        # Note: In a real GUI app, this would run in a separate thread to not block
        record_and_type()

def on_release(key):
    if key == keyboard.Key.esc:
        # Stop listener
        return False

# Start the global keyboard listener
with keyboard.Listener(on_press=on_press, on_release=on_release) as listener:
    listener.join()

```

#### **Step 3: Run It**

1. Open Terminal.
2. Run the script: `python3 glaido_clone.py`
3. **Grant Permissions:** macOS will ask for "Accessibility" (to control keys) and "Microphone" access. **You must allow these** in System Settings > Privacy & Security.
4. Open any app (Notes, Slack, etc.).
5. Press **F8**, speak clearly, and wait a second. The text will magically appear.

---

### Step 4: Turn it into a clickable App (Optional)

To make this look like a real Mac app (so you don't need the Terminal open):

1. **Install PyInstaller:**
```bash
pip install pyinstaller

```


2. **Build the App:**
```bash
pyinstaller --onefile --windowed --name "MyVoiceType" glaido_clone.py

```


3. **Locate your App:**
Go to the `dist` folder created in your directory. You will find `MyVoiceType.app`. You can drag this into your Applications folder.

### **Limitations vs. Real Glaido**

* **Speed:** This script uses Google's free API, which requires internet and has a slight delay. Glaido likely uses optimized local models.
* **Grammar:** This performs raw transcription. It won't intelligently add punctuation or fix "umms" and "ahhs" unless you integrate a smarter model like **OpenAI Whisper** (which is also free and open-source but requires a heavier setup).

To upgrade this to "Pro" level later, you would modify the `# 2. Convert Voice to Text` section to use `recorder.recognize_whisper(audio_data)` after installing the `openai-whisper` library.

... [Create a Text-to-Speech App with Swift](https://www.youtube.com/watch?v=G0gkQE6-ZA0)

I selected this video because although it focuses on iOS/Swift "voice coding," it visually demonstrates the powerful accessibility and dictation frameworks available in the Apple ecosystem, giving you context on how native voice control tools operate under the hood.

---

Here is the complete process to turn the previous script into a shareable Mac app.

### Phase 1: The "Friend-Friendly" Code

We will upgrade the script to use `rumps`. This puts a tiny microphone icon (🎙️) in the Mac menu bar, allowing your friends to see it's running and easily "Quit" it.

**1. Install the menu bar library:**

```bash
pip install rumps

```

**2. Save this as `glaido_app.py`:**

```python
import rumps
import threading
import speech_recognition as sr
from pynput import keyboard
import pyautogui
import tempfile
import os

class GlaidoApp(rumps.App):
    def __init__(self):
        super(GlaidoApp, self).__init__("🎙️")
        self.menu = ["Status: Idle", "Quit"]
        self.is_recording = False
        self.recorder = sr.Recognizer()
        
        # Start global hotkey listener in a separate thread
        self.listener_thread = threading.Thread(target=self.start_keyboard_listener, daemon=True)
        self.listener_thread.start()

    def start_keyboard_listener(self):
        # We listen for F8. 
        with keyboard.GlobalHotKeys({'<f8>': self.on_hotkey}) as h:
            h.join()

    def on_hotkey(self):
        # Toggle recording logic
        if not self.is_recording:
            self.is_recording = True
            rumps.notification("Glaido Clone", "Listening...", "Speak now!")
            self.title = "🔴" # Change icon to red circle
            self.record_and_type()
        else:
            # If we were already recording, we let the loop finish naturally 
            # or you can implement a force stop logic here.
            pass

    def record_and_type(self):
        # Run audio processing in a thread so it doesn't freeze the menu bar
        threading.Thread(target=self._process_audio).start()

    def _process_audio(self):
        try:
            with sr.Microphone() as source:
                self.recorder.adjust_for_ambient_noise(source, duration=0.2)
                # Listen for up to 10 seconds of speech
                audio = self.recorder.listen(source, timeout=5, phrase_time_limit=10)
            
            self.title = "⏳" # Hourglass while processing
            text = self.recorder.recognize_google(audio)
            
            # Type the text
            pyautogui.write(f"{text} ")
            
        except Exception as e:
            print(f"Error: {e}")
            rumps.notification("Error", "Could not recognize audio", str(e))
        finally:
            self.is_recording = False
            self.title = "🎙️" # Reset icon

if __name__ == "__main__":
    GlaidoApp().run()

```

---

### Phase 2: Create the `.app` Bundle

We will use `pyinstaller` to freeze this Python script into a standalone Mac application.

1. **Install PyInstaller:**
```bash
pip install pyinstaller

```


2. **Build the App:**
Run this command in your Terminal. It hides the console window (`--windowed`) and bundles everything into one file.
```bash
pyinstaller --noconfirm --onefile --windowed --name "GlaidoClone" --icon="icon.icns" glaido_app.py

```


*(Note: If you don't have an `icon.icns`, you can remove `--icon="icon.icns"`, or generate one online to make it look professional).*
3. **Test the App:**
Go to the `dist/` folder. You will see `GlaidoClone.app`. Double-click it. You should see a 🎙️ icon appear in your top menu bar.

---

### Phase 3: Create the `.dmg` Installer

To make it shareable, we wrap the `.app` into a `.dmg`. The easiest way is using a free tool called `create-dmg`.

1. **Install the tool (using Homebrew):**
```bash
brew install create-dmg

```


2. **Generate the DMG:**
Run this command inside the folder where your `dist` folder is located:
```bash
create-dmg \
  --volname "Glaido Installer" \
  --volicon "icon.icns" \
  --window-pos 200 120 \
  --window-size 800 400 \
  --icon-size 100 \
  --icon "GlaidoClone.app" 200 190 \
  --hide-extension "GlaidoClone.app" \
  --app-drop-link 600 185 \
  "GlaidoClone_Installer.dmg" \
  "dist/GlaidoClone.app"

```


*(If you don't have an icon, remove the `--volicon` line).*
3. **Result:** You now have `GlaidoClone_Installer.dmg`. This is the file you send to your friends!

---

### Phase 4: The "Friend Warning" (Crucial)

Because you are not an "Apple Verified Developer" (which costs $99/year), your friends will see a warning when they try to open your app:

> *"GlaidoClone" is damaged and can't be opened. You should move it to the Trash.*

**You must tell them how to open it:**

1. Drag the app to their **Applications** folder.
2. **Right-click** (or Control-click) the app icon.
3. Select **Open**.
4. A popup will appear asking if they are sure. Click **Open** again.
* *They only need to do this once. Afterward, it will open normally.*



### What should I do next?

Would you like me to explain how to swap the Google Speech engine with **OpenAI Whisper** (free, offline, and much more accurate) before you build the final DMG?
