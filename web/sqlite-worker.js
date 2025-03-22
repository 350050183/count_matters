// SQLite Web Worker
let db = null;
let dbData = null; // 用于在内存中保存数据库

// 检查是否在Worker环境中 - 更加严格的检查
const isInWorkerContext = (
    typeof self !== 'undefined' &&
    typeof window === 'undefined' &&
    typeof importScripts === 'function'
);

// 只在Worker环境中执行
if (isInWorkerContext) {
    console.log('Running in Worker context');

    // 确保sqlite3InitModule存在
    if (typeof self.sqlite3InitModule === 'undefined') {
        try {
            importScripts('sqlite3/sql-wasm.js');
            console.log('SQL WASM script loaded in worker');
        } catch (e) {
            console.error('Failed to load sql-wasm.js:', e);
        }
    }

    self.onmessage = async function (e) {
        const { id, action, params } = e.data;

        try {
            let result;
            switch (action) {
                case 'init':
                    await initializeSqlite();
                    result = { success: true };
                    break;
                case 'exec':
                    result = await execSql(params.sql, params.args);
                    // 操作执行后保存数据库
                    await persistDatabase();
                    break;
                case 'export':
                    result = await exportDatabase();
                    break;
                case 'import':
                    result = await importDatabase(params.data);
                    break;
                default:
                    throw new Error(`Unknown action: ${action}`);
            }
            self.postMessage({ id, result });
        } catch (error) {
            self.postMessage({ id, error: error.message || String(error) });
        }
    };
} else {
    console.warn('This script should only be used in a Web Worker context');
}

async function initializeSqlite() {
    if (!db) {
        try {
            console.log('Initializing SQLite...');
            if (!self.sqlite3InitModule) {
                console.error('sqlite3InitModule is not defined');
                throw new Error('SQLite module not available');
            }
            console.log('Calling sqlite3InitModule...');
            const sqlite3 = await self.sqlite3InitModule();
            console.log('sqlite3InitModule completed, creating DB...');

            // 尝试从IndexedDB加载保存的数据库
            try {
                const savedData = await loadFromIndexedDB('sqlite_db_data');
                if (savedData) {
                    console.log('Found saved database, restoring...');
                    db = new sqlite3.oo1.DB();
                    db.restore(savedData);
                    console.log('Database restored from saved data');
                } else {
                    console.log('No saved database found, creating new one');
                    db = new sqlite3.oo1.DB();
                }
            } catch (e) {
                console.warn('Failed to load saved database:', e);
                db = new sqlite3.oo1.DB();
            }

            console.log('DB created successfully');
        } catch (error) {
            console.error('Failed to initialize SQLite:', error);
            throw error;
        }
    }
}

async function execSql(sql, args = []) {
    if (!db) {
        throw new Error('Database not initialized');
    }
    return db.exec({ sql, bind: args });
}

// 导出数据库
async function exportDatabase() {
    if (!db) {
        throw new Error('Database not initialized');
    }
    const data = db.export();
    return new Uint8Array(data);
}

// 导入数据库
async function importDatabase(data) {
    if (!db) {
        throw new Error('Database not initialized');
    }
    db.restore(data);
    await persistDatabase();
    return { success: true };
}

// 持久化数据库到IndexedDB
async function persistDatabase() {
    if (!db) return;

    try {
        const data = db.export();
        await saveToIndexedDB('sqlite_db_data', data);
        console.log('Database persisted to IndexedDB');
        return true;
    } catch (e) {
        console.error('Failed to persist database:', e);
        return false;
    }
}

// IndexedDB存储函数
async function saveToIndexedDB(key, value) {
    return new Promise((resolve, reject) => {
        const request = indexedDB.open('SqliteStorage', 1);

        request.onupgradeneeded = function (event) {
            const db = event.target.result;
            if (!db.objectStoreNames.contains('keyvaluepairs')) {
                db.createObjectStore('keyvaluepairs');
            }
        };

        request.onsuccess = function (event) {
            const db = event.target.result;
            const transaction = db.transaction(['keyvaluepairs'], 'readwrite');
            const store = transaction.objectStore('keyvaluepairs');

            const storeRequest = store.put(value, key);

            storeRequest.onsuccess = function () {
                resolve(true);
            };

            storeRequest.onerror = function (e) {
                reject(e.target.error);
            };

            transaction.oncomplete = function () {
                db.close();
            };
        };

        request.onerror = function (event) {
            reject(event.target.error);
        };
    });
}

// 从IndexedDB加载数据
async function loadFromIndexedDB(key) {
    return new Promise((resolve, reject) => {
        const request = indexedDB.open('SqliteStorage', 1);

        request.onupgradeneeded = function (event) {
            const db = event.target.result;
            if (!db.objectStoreNames.contains('keyvaluepairs')) {
                db.createObjectStore('keyvaluepairs');
            }
        };

        request.onsuccess = function (event) {
            const db = event.target.result;

            if (!db.objectStoreNames.contains('keyvaluepairs')) {
                resolve(null);
                return;
            }

            const transaction = db.transaction(['keyvaluepairs'], 'readonly');
            const store = transaction.objectStore('keyvaluepairs');

            const getRequest = store.get(key);

            getRequest.onsuccess = function () {
                resolve(getRequest.result);
            };

            getRequest.onerror = function (e) {
                reject(e.target.error);
            };

            transaction.oncomplete = function () {
                db.close();
            };
        };

        request.onerror = function (event) {
            reject(event.target.error);
        };
    });
} 