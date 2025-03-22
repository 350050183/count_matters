let Module = {
    locateFile: function (s) {
        return 'sqlite3/sql-wasm.wasm';
    }
};

// 确保全局变量定义
let sqlite3InitModule;

// 检查是否在Worker环境中
const isInWorkerContext = (typeof self !== 'undefined' && typeof Window === 'undefined');

// 确保全局可用
try {
    if (isInWorkerContext && typeof importScripts === 'function') {
        // Worker环境中使用importScripts
        importScripts('sqlite3/sql-wasm.js');
        console.log('SQL WASM script loaded in worker');
        if (typeof self.sqlite3InitModule !== 'undefined') {
            sqlite3InitModule = self.sqlite3InitModule;
            console.log('sqlite3InitModule found and assigned in worker');
        } else {
            console.error('sqlite3InitModule not found after loading sql-wasm.js in worker');
        }
    } else {
        // 在主线程中，sqlite3/sql-wasm.js会通过HTML的script标签加载
        console.log('Not in worker, expecting sql-wasm.js to be loaded via script tag');
        // 等待sqlite3InitModule变为可用
        if (typeof window !== 'undefined' && typeof window.sqlite3InitModule !== 'undefined') {
            sqlite3InitModule = window.sqlite3InitModule;
            console.log('sqlite3InitModule found in window context');
        }
    }
} catch (e) {
    console.error('Failed to setup SQLite:', e);
}

let db;

// 导出sqlite3对象
const sqlite3API = {
    open: function (path) {
        if (!sqlite3InitModule) {
            throw new Error('SQLite module not initialized');
        }
        return sqlite3InitModule().then((sqlite3) => {
            db = new sqlite3.oo1.DB(path);
            return true;
        });
    },

    exec: function (sql, params) {
        if (!db) {
            throw new Error('Database not opened');
        }
        return db.exec({
            sql: sql,
            bind: params
        });
    },

    close: function () {
        if (db) {
            db.close();
            db = null;
            return true;
        }
        return false;
    }
};

// 确保在Worker和非Worker上下文中都能正确导出
if (isInWorkerContext) {
    self.sqlite3 = sqlite3API;
} else if (typeof window !== 'undefined') {
    window.sqlite3 = sqlite3API;
}

// 导出以便模块化使用
if (typeof module !== 'undefined' && module.exports) {
    module.exports = sqlite3API;
} 