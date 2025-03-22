// 检查是否在Worker环境中 - 更加严格的检查
const isInWorkerContext = (
    typeof self !== 'undefined' &&
    typeof window === 'undefined' &&
    typeof importScripts === 'function'
);

// 安全地导入sqlite3.js
if (isInWorkerContext) {
    try {
        importScripts('sqlite3.js');
        console.log('sqlite3.js loaded in worker context');
    } catch (e) {
        console.error('Failed to import sqlite3.js:', e);
    }
} else {
    console.warn('Not in worker context, cannot import sqlite3.js');
}

// 确保sqlite3对象存在
if (typeof self !== 'undefined') {
    if (!self.sqlite3) {
        console.warn('self.sqlite3 is not defined, creating mock implementation');
        self.sqlite3 = {
            open: function () {
                return Promise.reject('SQLite3 is not available');
            },
            exec: function () {
                return Promise.reject('SQLite3 is not available');
            },
            close: function () {
                return false;
            }
        };
    }
}

self.onmessage = async function (e) {
    const data = e.data;
    const id = data.id;
    const method = data.method;
    const params = data.params;

    try {
        let result;
        switch (method) {
            case 'open':
                result = await self.sqlite3.open(params.path);
                break;
            case 'exec':
                result = await self.sqlite3.exec(params.sql, params.params);
                break;
            case 'close':
                result = self.sqlite3.close();
                break;
            default:
                throw new Error('Unknown method: ' + method);
        }
        self.postMessage({ id, result });
    } catch (error) {
        console.error('Error in sqflite worker:', error);
        self.postMessage({ id, error: error.message || 'Unknown error' });
    }
};