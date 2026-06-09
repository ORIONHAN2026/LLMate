// test.js - 测试文件
// 生成时间: 2026-06-09T00:02:09.943Z

function add(a, b) {
  return a + b;
}

function multiply(a, b) {
  return a * b;
}

function greet(name) {
  return `Hello, ${name}!`;
}

// 测试用例
console.log('=== 测试开始 ===');

console.log('add(2, 3):', add(2, 3));
console.assert(add(2, 3) === 5, 'add 测试失败');

console.log('multiply(4, 5):', multiply(4, 5));
console.assert(multiply(4, 5) === 20, 'multiply 测试失败');

console.log('greet("World"):', greet('World'));
console.assert(greet('World') === 'Hello, World!', 'greet 测试失败');

console.log('=== 测试完成 ===');

module.exports = { add, multiply, greet };
