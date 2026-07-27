# 21Days mobile ↔ media-resources

This Flutter app talks to the **21days-media-resources** Flask API.

- Backend path (sibling): `../21days-media-resources`
- API implementation: `../21days-media-resources/api/flask_api_server.py`
- Design doc: `../21days-media-resources/DESIGN.md`
- Live session links config: `../21days-media-resources/config/live_sessions.json`

Cursor rule for API shapes: `.cursor/rules/media-resources-api.mdc`

To give the agent full backend context in a session, either:

1. Open the multi-root workspace file:
   `/Users/pawansaxena/playpen/21days.code-workspace`
   (Cursor: **File → Open Workspace from File…**, or open that file from Finder)
2. `@`-mention backend files (e.g. `@flask_api_server.py`, `@DESIGN.md`) in chat.

If **File → Add Folder to Workspace…** is missing, you are likely in the Agents window — use the Editor, Command Palette (`Add Folder to Workspace`), or the `.code-workspace` file above.