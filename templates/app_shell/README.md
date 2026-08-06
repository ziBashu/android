# App shell template

Prefer generating new apps with:

```powershell
. .\scripts\env.ps1
.\scripts\new_app.ps1 -Slug mytool -Name "MyTool" -Surface tool
```

That runs `flutter create`, sets `applicationId` to `com.zibashu.<slug>`, and wires path deps to the shared packages.
