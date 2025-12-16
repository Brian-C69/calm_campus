# Gemini Integration in CalmCampus

This document outlines the integration of Google's Gemini API into the CalmCampus application, specifically for powering the AI Buddy feature.

## 1. Overview
The AI Buddy in CalmCampus leverages the Gemini API to provide intelligent, context-aware, and empathetic interactions with users. Gemini's advanced natural language understanding and generation capabilities enhance the AI Buddy's ability to reflect feelings, break down tasks, and suggest relevant CalmCampus tools.

## 2. Key Capabilities Enhanced by Gemini
*   **Advanced Natural Language Understanding:** More nuanced interpretation of user input for relevant and empathetic responses.
*   **Contextual Suggestions:** Personalized suggestions based on user data (mood, sleep, timetable) for coping strategies or tool recommendations.
*   **Ethical AI Handling:** Adherence to strict ethical guidelines, ensuring non-diagnostic, non-judgmental, and safety-prioritized responses. Redirection to real-world support in crisis situations.

## 3. Setup and Configuration

### 3.1 API Key Management
To use the Gemini API, an API key is required. This key should be stored securely and not hardcoded directly into the application's source code.

**For local development:**
*   Create a `.env` file in the `ai-buddy-server` directory (or wherever your backend is hosted).
*   Add your Gemini API key to this file:
    ```
    GEMINI_API_KEY=YOUR_GEMINI_API_KEY
    ```
*   Ensure `.env` is included in `.gitignore` to prevent it from being committed to version control.

**For deployment:**
*   Utilize environment variables or a secure secret management service provided by your hosting platform (e.g., Google Cloud Secret Manager, AWS Secrets Manager, Vercel Environment Variables).

### 3.2 Backend Integration
The `ai-buddy-server` (or equivalent backend service) is responsible for handling communication with the Gemini API.

**Example (Node.js with `ai-buddy-server/src/index.js`):**

The backend will need to:
1.  Load the `GEMINI_API_KEY` from environment variables.
2.  Initialize the Gemini client.
3.  Receive user messages and contextual data from the Flutter frontend.
4.  Send requests to the Gemini API.
5.  Process Gemini's responses and format them for the frontend, including any `follow_up_question` or `suggested_actions`.

**Dependencies:**
Ensure your backend project includes the necessary Gemini client library. For Node.js, this would typically be `@google/generative-ai`.

```json
// ai-buddy-server/package.json (example snippet)
{
  "dependencies": {
    "@google/generative-ai": "^0.x.x",
    "dotenv": "^x.x.x",
    // ... other dependencies
  }
}
```

### 3.3 Frontend Integration (Flutter)
The Flutter application communicates with your backend service, not directly with the Gemini API.

**Example (`lib/services/chat_service.dart` or similar):**

The frontend will need to:
1.  Send user messages and relevant context (mood, sleep, timetable, etc.) to the `ai-buddy-server`'s chat endpoint.
2.  Receive and display the AI Buddy's response.
3.  Handle `suggested_actions` by presenting them as actionable chips or buttons.

## 4. Ethical Considerations and Safety Guidelines
*   **No Diagnosis or Medical Advice:** The AI Buddy must never provide medical diagnoses or act as a substitute for professional medical or psychological advice.
*   **Crisis Redirection:** In situations indicating a crisis, the AI Buddy should *immediately* and *gently* redirect the user to the HelpNow page and encourage them to contact real-world support (e.g., "safe people," counselors, crisis hotlines).
*   **Privacy:** Ensure no sensitive user data is sent to Gemini without explicit user consent. Data sent should be minimal and anonymized where possible.
*   **Transparency:** Users should be aware that they are interacting with an AI.
*   **Non-Judgmental Tone:** Responses should always maintain a supportive, empathetic, and non-judgmental tone.

## 5. Testing
Thorough testing should be conducted to ensure:
*   API key is loaded correctly.
*   Communication between frontend -> backend -> Gemini API -> backend -> frontend is robust.
*   Ethical guidelines, especially crisis redirection, are correctly implemented and triggered.
*   Responses are relevant, helpful, and align with the AI Buddy's persona.
