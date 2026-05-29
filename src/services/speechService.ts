export class SpeechService {
  private recognition: SpeechRecognition | null = null;
  private isListening = false;
  private lastRecognizedWords = '';
  private onResultCallback: ((text: string) => void) | null = null;
  private onListeningCallback: (() => void) | null = null;
  private onStoppedCallback: (() => void) | null = null;

  get listening(): boolean {
    return this.isListening;
  }

  get lastResult(): string {
    return this.lastRecognizedWords;
  }

  initialize(): void {
    const SpeechRecognition = (window as unknown as { 
      SpeechRecognition: typeof window.SpeechRecognition; 
      webkitSpeechRecognition: typeof window.SpeechRecognition 
    }).SpeechRecognition ||
      (window as unknown as { webkitSpeechRecognition: typeof window.SpeechRecognition }).webkitSpeechRecognition;

    if (SpeechRecognition) {
      this.recognition = new SpeechRecognition();
      this.recognition.continuous = false;
      this.recognition.interimResults = true;
      this.recognition.lang = 'zh-CN';

      this.recognition.onresult = (event: SpeechRecognitionEvent) => {
        const results = Array.from(event.results);
        const transcript = results
          .map(result => result[0].transcript)
          .join('');
        this.lastRecognizedWords = transcript;
        if (this.onResultCallback) {
          this.onResultCallback(transcript);
        }
      };

      this.recognition.onerror = (event: SpeechRecognitionError) => {
        console.error('Speech recognition error:', event.error);
        this.stopListening();
      };

      this.recognition.onend = () => {
        if (this.isListening) {
          this.isListening = false;
          if (this.onStoppedCallback) {
            this.onStoppedCallback();
          }
        }
      };
    } else {
      console.error('Speech recognition is not supported in this browser');
    }
  }

  startListening(
    onResult: (text: string) => void,
    onListening: () => void,
    onStopped: () => void
  ): void {
    if (!this.recognition) {
      console.error('Speech recognition not initialized');
      return;
    }

    if (this.isListening) {
      this.stopListening();
    }

    this.onResultCallback = onResult;
    this.onListeningCallback = onListening;
    this.onStoppedCallback = onStopped;
    this.isListening = true;

    if (this.onListeningCallback) {
      this.onListeningCallback();
    }

    try {
      this.recognition.start();
    } catch (error) {
      console.error('Failed to start listening:', error);
      this.isListening = false;
    }
  }

  stopListening(): void {
    if (this.recognition && this.isListening) {
      try {
        this.recognition.stop();
      } catch (error) {
        console.error('Failed to stop listening:', error);
      }
      this.isListening = false;
      if (this.onStoppedCallback) {
        this.onStoppedCallback();
      }
    }
  }

  cancelListening(): void {
    if (this.recognition) {
      try {
        this.recognition.abort();
      } catch (error) {
        console.error('Failed to cancel listening:', error);
      }
      this.isListening = false;
      if (this.onStoppedCallback) {
        this.onStoppedCallback();
      }
    }
  }

  speak(text: string): void {
    if ('speechSynthesis' in window) {
      const utterance = new SpeechSynthesisUtterance(text);
      utterance.lang = 'zh-CN';
      utterance.rate = 0.8;
      utterance.volume = 1.0;
      window.speechSynthesis.speak(utterance);
    } else {
      console.error('Text-to-speech is not supported in this browser');
    }
  }

  stopSpeaking(): void {
    if ('speechSynthesis' in window) {
      window.speechSynthesis.cancel();
    }
  }
}
