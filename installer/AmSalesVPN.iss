; ─────────────────────────────────────────────────────────────────────────
;  Inno Setup скрипт установщика AM.SALES VPN.
;  Упаковывает собранное приложение (build/) со всеми движками в setup.exe.
; ─────────────────────────────────────────────────────────────────────────

#define AppName "AM.SALES VPN"
#define AppVersion "1.0.13"
#define AppPublisher "AM.SALES"
#define AppExe "AmSalesVPN.exe"

[Setup]
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher={#AppPublisher}
; Папка установки по умолчанию: Program Files\AM.SALES VPN
DefaultDirName={autopf}\AM.SALES VPN
DefaultGroupName=AM.SALES VPN
DisableProgramGroupPage=yes
; Итоговый файл установщика кладём в installer\output
OutputDir=output
OutputBaseFilename=AmSalesVPN-Setup
Compression=lzma2/max
SolidCompression=yes
; Приложению нужны админ-права (TUN, WinDivert) — ставим в Program Files
PrivilegesRequired=admin
; Иконка самого установщика и uninstall
SetupIconFile=..\assets\app.ico
UninstallDisplayIcon={app}\{#AppExe}
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
; Автообновление: если AmSalesVPN.exe запущен — закрыть его (force) и
; перезапустить после установки. AppId фиксируем, чтобы новая версия
; ставилась поверх старой (а не в отдельную папку).
AppId={{B7C8E2A4-9D3F-4E51-B6A2-3A5D8E6F7C12}
CloseApplications=force
CloseApplicationsFilter=*.exe
RestartApplications=yes

[Languages]
Name: "russian"; MessagesFile: "compiler:Languages\Russian.isl"

[Tasks]
Name: "desktopicon"; Description: "Создать ярлык на рабочем столе"; GroupDescription: "Дополнительно:"
Name: "autostart"; Description: "Запускать при старте Windows"; GroupDescription: "Дополнительно:"; Flags: unchecked

[Files]
; Копируем ВСЁ содержимое build/ (exe + Qt dll + qml + engine с движками)
Source: "..\build\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs ignoreversion

[Icons]
; Меню Пуск
Name: "{group}\AM.SALES VPN"; Filename: "{app}\{#AppExe}"; IconFilename: "{app}\{#AppExe}"
Name: "{group}\Удалить AM.SALES VPN"; Filename: "{uninstallexe}"
; Рабочий стол (по галке)
Name: "{autodesktop}\AM.SALES VPN"; Filename: "{app}\{#AppExe}"; IconFilename: "{app}\{#AppExe}"; Tasks: desktopicon

[Registry]
; Автозапуск (по галке) — от текущего пользователя
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueType: string; ValueName: "AmSalesVPN"; ValueData: """{app}\{#AppExe}"""; Flags: uninsdeletevalue; Tasks: autostart

[Run]
; ── 1. Обычная установка: галка "Запустить" в финальном диалоге. ─────────
;      Пропускается в /VERYSILENT (skipifsilent), там работает запись ниже.
; shellexec + runasoriginaluser — чтобы UAC корректно поднял права
; (приложению нужен admin-манифест), иначе CreateProcess падает с 740.
Filename: "{app}\{#AppExe}"; Description: "Запустить AM.SALES VPN"; Flags: postinstall skipifsilent shellexec runasoriginaluser nowait

; ── 2. Тихая установка (автообновление из приложения): запуск без галки. ─
; Срабатывает только при /VERYSILENT — стандартный setup не задваивает.
; ВАЖНО: используем shellexec — он идёт через ShellExecuteEx, который
; ЧИТАЕТ манифест requireAdministrator и покажет UAC, если elevation не
; наследуется (бывает в Inno-режиме installmode admin). Без shellexec
; CreateProcess игнорирует манифест → exe запускается с filtered-токеном
; и sing-box падает: "configure tun interface: Access is denied".
Filename: "{app}\{#AppExe}"; Flags: shellexec nowait; Check: WizardSilent

[UninstallDelete]
; Чистим за собой движок/кэш при удалении
Type: filesandordirs; Name: "{app}\engine"
