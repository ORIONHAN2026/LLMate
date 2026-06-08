/**
 * 微信支付首页 - 仿制版 JavaScript
 */

(function() {
    'use strict';

    // ===== Banner 轮播 =====
    var Slider = {
        current: 0,
        total: 0,
        timer: null,
        interval: 4000,

        init: function() {
            var slides = document.querySelectorAll('.slider .slide-item');
            var dots = document.querySelectorAll('.slider-dots li');
            this.total = slides.length;
            if (this.total === 0) return;

            // 点击指示点切换
            var self = this;
            dots.forEach(function(dot, index) {
                dot.addEventListener('click', function() {
                    self.goTo(index);
                    self.resetTimer();
                });
            });

            // 自动播放
            this.startAuto();
        },

        goTo: function(index) {
            var slides = document.querySelectorAll('.slider .slide-item');
            var dots = document.querySelectorAll('.slider-dots li');

            slides[this.current].classList.remove('active');
            dots[this.current].classList.remove('active');

            this.current = index;

            slides[this.current].classList.add('active');
            dots[this.current].classList.add('active');
        },

        next: function() {
            var next = (this.current + 1) % this.total;
            this.goTo(next);
        },

        startAuto: function() {
            var self = this;
            this.timer = setInterval(function() {
                self.next();
            }, this.interval);
        },

        resetTimer: function() {
            clearInterval(this.timer);
            this.startAuto();
        }
    };

    // ===== 解决方案 Accordion =====
    var Accordion = {
        init: function() {
            var items = document.querySelectorAll('.accordion li');
            var self = this;

            items.forEach(function(item) {
                item.addEventListener('mouseenter', function() {
                    items.forEach(function(el) {
                        el.classList.remove('selected');
                    });
                    this.classList.add('selected');
                });
            });

            // 默认选中第一个
            if (items.length > 0) {
                items[0].classList.add('selected');
            }

            // 鼠标离开整个accordion区域时，恢复第一个选中
            var accordion = document.querySelector('.accordion');
            if (accordion) {
                accordion.addEventListener('mouseleave', function() {
                    items.forEach(function(el) {
                        el.classList.remove('selected');
                    });
                    if (items.length > 0) {
                        items[0].classList.add('selected');
                    }
                });
            }
        }
    };

    // ===== 登录切换 =====
    var LoginSwitch = {
        init: function() {
            var wechatLogin = document.getElementById('wechatLogin');
            var accountLogin = document.getElementById('accountLogin');
            var switchToAccount = document.querySelector('#wechatLogin .switch-icon');
            var switchToWechat = document.querySelector('#accountLogin .switch-icon');

            if (switchToAccount) {
                switchToAccount.addEventListener('click', function() {
                    wechatLogin.classList.add('hide');
                    accountLogin.classList.remove('hide');
                });
            }

            if (switchToWechat) {
                switchToWechat.addEventListener('click', function() {
                    accountLogin.classList.add('hide');
                    wechatLogin.classList.remove('hide');
                });
            }
        }
    };

    // ===== 导航选中状态 =====
    var Navigation = {
        init: function() {
            var navLinks = document.querySelectorAll('.header .link > a:not(.btn-apply)');
            navLinks.forEach(function(link) {
                link.addEventListener('click', function(e) {
                    navLinks.forEach(function(l) {
                        l.classList.remove('selected');
                    });
                    this.classList.add('selected');
                });
            });
        }
    };

    // ===== 初始化 =====
    document.addEventListener('DOMContentLoaded', function() {
        Slider.init();
        Accordion.init();
        LoginSwitch.init();
        Navigation.init();
        console.log('微信支付首页已就绪');
    });

})();
