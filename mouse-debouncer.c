#include <windows.h>
#include <stdio.h>
#include <time.h>

#define DEBOUNCE_INTERVAL_MS 50

HHOOK mouseHook;
DWORD lastClickTime = 0;

LRESULT CALLBACK MouseProc(int nCode, WPARAM wParam, LPARAM lParam) {
    if (nCode >= 0) {
        if (wParam == WM_LBUTTONDOWN || wParam == WM_LBUTTONUP) {
            DWORD currentTime = GetTickCount();
            DWORD elapsed = currentTime - lastClickTime;
            if(wParam == WM_LBUTTONDOWN)printf("down %u\n",elapsed);
            if(wParam == WM_LBUTTONUP)printf("up %u\n",elapsed);
            if (elapsed < DEBOUNCE_INTERVAL_MS) {
                // Suppress event (debounced)
                return 1; // Non-zero means event is blocked
            }

            lastClickTime = currentTime;
        }
    }

    return CallNextHookEx(mouseHook, nCode, wParam, lParam);
}

int main() {
    MSG msg;

    // Set the global mouse hook
    mouseHook = SetWindowsHookEx(WH_MOUSE_LL, MouseProc, NULL, 0);
    if (mouseHook == NULL) {
        MessageBox(NULL, "Failed to install mouse hook!", "Error", MB_ICONERROR);
        return 1;
    }

    printf("Mouse debounce filter running... Press Ctrl+C to exit.\n");

    // Message loop to keep the hook alive
    while (GetMessage(&msg, NULL, 0, 0)) {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }

    // Cleanup
    UnhookWindowsHookEx(mouseHook);
    return 0;
}
