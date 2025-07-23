#pragma comment(lib, "user32.lib")

#include <windows.h>
#include <stdio.h>
#include <time.h>

#define DEBOUNCE_INTERVAL_MS 50

HHOOK mouseHook;
DWORD lastClickTime = 0;
char buff[100]={0};
short blockNext=0;

LRESULT CALLBACK MouseProc(int nCode, WPARAM wParam, LPARAM lParam) {
    if (nCode >= 0) {
        if (wParam == WM_LBUTTONDOWN || wParam == WM_LBUTTONUP) {
            DWORD currentTime = GetTickCount();
            DWORD elapsed = currentTime - lastClickTime;
            if(wParam == WM_LBUTTONDOWN)sprintf(buff,"down %u\n",elapsed);
            if(wParam == WM_LBUTTONUP)sprintf(buff,"up %u\n",elapsed);
            OutputDebugStringA(buff);
            if(blockNext){
                blockNext=0;
                if(wParam == WM_LBUTTONDOWN){
                    OutputDebugStringA("blockNext");
                    return 1;
                }
                else{
                    OutputDebugStringA("not blockNext up");
                }
            }
            else if (elapsed < DEBOUNCE_INTERVAL_MS) {
                // Suppress event (debounced)
                blockNext=1;
                OutputDebugStringA("block");
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

    OutputDebugStringA("Mouse debounce filter running...\n");

    // Message loop to keep the hook alive
    while (GetMessage(&msg, NULL, 0, 0)) {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
    }

    // Cleanup
    UnhookWindowsHookEx(mouseHook);
    return 0;
}
