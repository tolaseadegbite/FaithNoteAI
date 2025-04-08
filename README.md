FaithNoteAI is a Rails application designed to enhance spiritual study and note-taking with AI-powered features. It combines sermon note-taking, Bible study tools, and AI assistance to create a comprehensive platform for faith-based learning and reflection.

## Features
### Note Taking & Management
- Sermon Notes : Create, edit, and organize sermon notes with rich text formatting
- Audio Support : Upload audio recordings of sermons for transcription
- AI-Generated Summaries : Automatically generate summaries of your notes using AI
### Bible Study Tools
- Bible Verse Lookup : Search and view Bible verses in multiple translations
- Chapter View : Read entire chapters with easy navigation
- Verse References : Automatic detection and linking of Bible references in notes and chats
### AI-Powered Chat
- Bible Chat : Ask questions about the Bible and receive AI-generated responses
- Note Chat : Discuss and explore your sermon notes with AI assistance
- Verse Integration : Bible verses are automatically detected, linked, and displayed in chat responses
### User Experience
- Responsive Design : Works seamlessly on desktop and mobile devices
- Dark Mode Support : Comfortable reading in any lighting condition
- Modal Dialogs : View Bible verses without losing your place in conversations
- PWA Support : Install as a Progressive Web App for offline access
## Technical Stack
- Framework : Ruby on Rails 8.0
- Database : PostgreSQL
- Frontend : Tailwind CSS, Stimulus.js
- AI Integration : Google Gemini API
- Authentication : Custom authentication system
- Real-time Updates : Turbo Streams
- Deployment : Docker-ready with Kamal support
## Getting Started
### Prerequisites
- Ruby 3.3.1
- PostgreSQL
- Node.js and Yarn
### Installation
1. Clone the repository
2. Install dependencies
3. Setup the database
4. Start the development server
5. Visit http://localhost:3000 in your browser
## Development
### Key Components
- Notes System : Manage sermon notes with transcription and AI summaries
- Bible Database : Complete Bible text with multiple translations
- Chat System : AI-powered conversations about the Bible and notes
- Bible Verse Processor : Detects and links Bible references in text
### Testing
Run the test suite with:

```bash
bin/rails test
 ```

## Deployment
The application includes Docker configuration for easy deployment:

```bash
docker build -t faith_note_ai .
docker run -d -p 80:80 -e RAILS_MASTER_KEY=<value from config/master.key> --name faith_note_ai faith_note_ai
 ```
```

For production deployment, Kamal configuration is included:

```bash
bin/kamal setup
bin/kamal deploy
 ```
