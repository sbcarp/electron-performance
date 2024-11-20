import { app, BrowserWindow, Menu, MenuItemConstructorOptions } from 'electron'
const prompt = require('custom-electron-prompt')

export function buildApplicationMenu(mainWindow: BrowserWindow) {
    const isMac = process.platform === 'darwin'

    const template: MenuItemConstructorOptions[] = [
        // Application Menu (macOS only)
        ...(isMac
            ? [
                {
                    label: app.name,
                    submenu: [
                        { role: 'about' as const },
                        { type: 'separator' as const },
                        { role: 'services' as const },
                        { type: 'separator' as const },
                        { role: 'hide' as const },
                        { role: 'hideOthers' as const },
                        { role: 'unhide' as const },
                        { type: 'separator' as const },
                        { role: 'quit' as const }
                    ]
                }
            ]
            : []),

        // File Menu
        {
            label: 'File',
            submenu: [isMac ? { role: 'close' as const } : { role: 'quit' as const }]
        },

        // Edit Menu
        {
            label: 'Edit',
            submenu: [
                { role: 'undo' as const },
                { role: 'redo' as const },
                { type: 'separator' as const },
                { role: 'cut' as const },
                { role: 'copy' as const },
                { role: 'paste' as const },
                ...(isMac
                    ? [
                        { role: 'pasteAndMatchStyle' as const },
                        { role: 'delete' as const },
                        { role: 'selectAll' as const },
                        { type: 'separator' as const },
                        {
                            label: 'Speech',
                            submenu: [{ role: 'startSpeaking' as const }, { role: 'stopSpeaking' as const }]
                        }
                    ]
                    : [
                        { role: 'delete' as const },
                        { type: 'separator' as const },
                        { role: 'selectAll' as const }
                    ])
            ]
        },

        // View Menu
        {
            label: 'View',
            submenu: [
                { role: 'reload' as const },
                { role: 'forceReload' as const },
                { role: 'toggleDevTools' as const },
                { type: 'separator' as const },
                { role: 'resetZoom' as const },
                { role: 'zoomIn' as const },
                { role: 'zoomOut' as const },
                { type: 'separator' as const },
                { role: 'togglefullscreen' as const }
            ]
        },

        // Window Menu
        {
            label: 'Window',
            submenu: [
                { role: 'minimize' as const },
                { role: 'zoom' as const },
                ...(isMac
                    ? [
                        { type: 'separator' as const },
                        { role: 'front' as const },
                        { type: 'separator' as const },
                        { role: 'window' as const }
                    ]
                    : [{ role: 'close' as const }])
            ]
        },

        // Help Menu
        {
            role: 'help' as const,
            submenu: [
                {
                    label: 'Learn More',
                    click: async () => {
                        const { shell } = require('electron')
                        await shell.openExternal('https://electronjs.org')
                    }
                }
            ]
        },

        // **Your Custom Menu**
        {
            label: 'Debug',
            submenu: [
                {
                    label: 'Open URL',
                    click: async () => {
                        prompt({
                            title: 'Go to',
                            label: 'URL:',
                            value: '',
                            inputAttrs: {
                                type: 'url'
                            },
                            type: 'input'
                        })
                            .then((r) => {
                                if (r) {
                                    mainWindow.loadURL(r);
                                    console.log('result', r);
                                }
                            })
                            .catch(console.error);

                    },
                },
                {
                    label: 'Open Media Decode Test',
                    click: () => {
                        mainWindow.loadURL('file:///Volumes/workplace/WickrWebPerformance/index.html');
                    },
                },
                {
                    label: 'Open Browserbench',
                    click: () => {
                        mainWindow.loadURL('https://browserbench.org/');
                    },
                }
                ,
                {
                    label: 'Open GPU',
                    click: () => {
                        mainWindow.loadURL('chrome://gpu');
                    },
                }
            ]
        }
    ]

    const menu = Menu.buildFromTemplate(template)
    Menu.setApplicationMenu(menu)
}
