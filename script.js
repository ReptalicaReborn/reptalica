document.addEventListener('DOMContentLoaded', () => {
    // ═══════════════════════════════════════
    // Gallery Filter & Search
    // ═══════════════════════════════════════
    const filterDropdown = document.getElementById('gallery-filter');
    const searchInput = document.getElementById('gallery-search');
    const galleryItems = document.querySelectorAll('.card[data-category]');

    function filterGallery() {
        const filterValue = filterDropdown.value;
        const searchValue = searchInput.value.toLowerCase().trim();

        galleryItems.forEach(item => {
            const category = item.getAttribute('data-category');
            const title = item.querySelector('.card__title').textContent.toLowerCase();
            const desc = item.querySelector('.card__desc').textContent.toLowerCase();

            const matchesCategory = (filterValue === 'all' || category === filterValue);
            const matchesSearch = (title.includes(searchValue) || desc.includes(searchValue));

            if (matchesCategory && matchesSearch) {
                item.classList.remove('hidden');
                item.style.display = '';
            } else {
                item.classList.add('hidden');
                item.style.display = 'none';
            }
        });
    }

    if (filterDropdown && searchInput) {
        filterDropdown.addEventListener('change', filterGallery);
        searchInput.addEventListener('input', filterGallery);
    }

    // ═══════════════════════════════════════
    // Modal
    // ═══════════════════════════════════════
    const modal = document.getElementById('preview-modal');
    if (modal) {
        const modalImg = document.getElementById('modal-image');
        const modalTitle = document.getElementById('modal-title');
        const modalDesc = document.getElementById('modal-desc');
        const downloadBtn = document.getElementById('download-btn');
        const closeBtn = modal.querySelector('.modal__close');
        const backdrop = modal.querySelector('.modal__backdrop');

        function openModal(item) {
            const img = item.querySelector('img');
            const title = item.querySelector('.card__title').textContent;
            const desc = item.querySelector('.card__desc').textContent;

            modalImg.src = img.src.replace('assets/thumbnails', 'assets/optimized');
            modalTitle.textContent = title;
            modalDesc.textContent = desc;

            const downloadUrl = img.src.replace('assets/thumbnails', 'assets/original').replace('.webp', '.png');
            downloadBtn.href = downloadUrl;
            downloadBtn.setAttribute('download', downloadUrl.split('/').pop());

            modal.classList.add('active');
            modal.setAttribute('aria-hidden', 'false');
            document.body.style.overflow = 'hidden';
        }

        function closeModal() {
            modal.classList.remove('active');
            modal.setAttribute('aria-hidden', 'true');
            document.body.style.overflow = '';
        }

        galleryItems.forEach(item => {
            item.addEventListener('click', () => openModal(item));
        });

        closeBtn.addEventListener('click', closeModal);
        backdrop.addEventListener('click', closeModal);

        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape' && modal.classList.contains('active')) {
                closeModal();
            }
        });
    }

    // ═══════════════════════════════════════
    // Email Copy
    // ═══════════════════════════════════════
    const emailBtn = document.getElementById('email-btn');
    if (emailBtn) {
        emailBtn.addEventListener('click', (e) => {
            e.preventDefault();
            const email = 'reptalica@shitposting.expert';
            navigator.clipboard.writeText(email).then(() => {
                showToast('Copied "reptalica@shitposting.expert" to clipboard');
            }).catch(() => {
                showToast('Email: ' + email);
            });
        });
    }

    // ═══════════════════════════════════════
    // Toast
    // ═══════════════════════════════════════
    function showToast(message) {
        const toast = document.createElement('div');
        toast.className = 'toast';
        toast.textContent = message;
        document.body.appendChild(toast);

        // Trigger reflow
        toast.offsetHeight;
        toast.classList.add('show');

        setTimeout(() => {
            toast.classList.remove('show');
            setTimeout(() => {
                if (document.body.contains(toast)) {
                    document.body.removeChild(toast);
                }
            }, 300);
        }, 3000);
    }

    // ═══════════════════════════════════════
    // Entrance Animations (Intersection Observer)
    // ═══════════════════════════════════════
    const revealElements = document.querySelectorAll('.section__header, .about__grid, .gallery__controls, .card');

    revealElements.forEach(el => el.classList.add('reveal'));

    const observer = new IntersectionObserver((entries) => {
        entries.forEach((entry) => {
            if (entry.isIntersecting) {
                // Stagger animation for cards
                const delay = entry.target.classList.contains('card')
                    ? Array.from(galleryItems).indexOf(entry.target) % 6 * 80
                    : 0;

                setTimeout(() => {
                    entry.target.classList.add('visible');
                    // Stop observing once revealed — prevents flicker on scroll
                    observer.unobserve(entry.target);
                }, delay);
            }
        });
    }, {
        threshold: 0.1,
        rootMargin: '0px 0px -50px 0px'
    });

    revealElements.forEach(el => observer.observe(el));

    // ═══════════════════════════════════════
    // Orbital Acceleration Easter Egg (Long Press)
    // ═══════════════════════════════════════
    const hero = document.getElementById('hero');
    let isAccelerating = false;
    let accelerationProgress = 0; // 0 to 1
    let animationFrameId = null;
    let transitioning = false;
    let lastVibrateTime = 0;
    let isTouchInput = false;

    // Cache DOM elements
    const elementsToAccelerate = document.querySelectorAll('.orbital-ring, .orbital-dot');
    const orbitalRings = document.querySelectorAll('.orbital-ring');
    const orbitalRing1 = document.querySelector('.orbital-ring--1');
    const noiseOverlay = document.querySelector('.noise-overlay');

    // Cache animations
    let cachedAnims = [];

    function updateAcceleration(timestamp) {
        if (transitioning) return;

        if (isAccelerating) {
            // Cut desktop long press time by ~0.5 (make increment larger if not touch)
            const increment = isTouchInput ? 0.004 : 0.008;
            accelerationProgress = Math.min(1, accelerationProgress + increment);

            // Cross-browser vibration support
            const vibrateFunc = navigator.vibrate || navigator.webkitVibrate || navigator.mozVibrate || navigator.msVibrate;

            // Engine rev haptic: heavy "cylinder firing" pulses
            // that get faster and harder as RPM climbs
            if (vibrateFunc) {
                const now = timestamp || performance.now();
                const p = accelerationProgress; // 0 → 1

                // Gap between pulses: 250ms at idle → 30ms at redline
                const gap = 250 - (p * 220);
                // Pulse duration: 40ms thump at idle → 150ms slam at redline
                const pulse = 40 + (p * 110);

                if (now - lastVibrateTime > gap) {
                    if (p < 0.3) {
                        // Low RPM — heavy single thumps (idle chug)
                        vibrateFunc.call(navigator, pulse);
                    } else if (p < 0.7) {
                        // Mid RPM — double-slam like cylinders firing
                        vibrateFunc.call(navigator, [pulse, 15, pulse * 0.8]);
                    } else {
                        // High RPM — rapid triple slam (redline)
                        vibrateFunc.call(navigator, [pulse, 8, pulse * 0.85, 8, pulse * 0.7]);
                    }
                    lastVibrateTime = now;
                }
            }
        } else {
            accelerationProgress = Math.max(0, accelerationProgress - 0.03); // slow down faster
        }

        // Use a cubic ease-in for dramatic effect
        const easeIn = accelerationProgress * accelerationProgress * accelerationProgress;

        // speed factor: from 1x up to 50x
        const speed = 1 + (easeIn * 49);

        // Update cached animations
        cachedAnims.forEach(anim => {
            anim.playbackRate = speed;
        });

        // Delegate rendering via CSS Variable for GPU-friendly opacity transitions!
        if (hero) {
            hero.style.setProperty('--accel', easeIn);
        }

        if (noiseOverlay) {
            noiseOverlay.style.opacity = 0.03 + (easeIn * 0.15);
        }

        if (accelerationProgress >= 0.99 && !transitioning) {
            transitioning = true;

            const vibrateFunc = navigator.vibrate || navigator.webkitVibrate || navigator.mozVibrate || navigator.msVibrate;
            // Final haptic: engine redline burst then heavy sustained crush
            if (vibrateFunc) {
                vibrateFunc.call(navigator, [
                    60, 10, 60, 10, 60, 10, 60, 10, // aggressive rapid fire
                    30,                               // brief gap
                    600                               // heavy sustained crush buzz
                ]);
            }

            // ── ELEMENT SCATTER — fling everything off screen ──
            const flingSpeed = 'transform 0.35s cubic-bezier(0.5, 0, 1, 0.3), opacity 0.3s ease-in';

            // Title — shoots up
            const heroContent = hero.querySelector('.hero__content');
            if (heroContent) {
                heroContent.style.transition = flingSpeed;
                heroContent.style.transform = 'translateY(-120vh) rotate(-8deg)';
                heroContent.style.opacity = '0';
            }

            // Nav — flies down
            const heroNav = hero.querySelector('.hero__nav');
            if (heroNav) {
                heroNav.style.transition = flingSpeed;
                heroNav.style.transform = 'translateY(120vh) rotate(5deg)';
                heroNav.style.opacity = '0';
            }

            // Scroll hint — drops off bottom-right
            const scrollHint = hero.querySelector('.hero__scroll-hint');
            if (scrollHint) {
                scrollHint.style.transition = flingSpeed;
                scrollHint.style.transform = 'translate(80vw, 120vh)';
                scrollHint.style.opacity = '0';
            }

            // Ring 1 — flings top-left
            if (orbitalRing1) {
                orbitalRing1.style.transition = flingSpeed;
                orbitalRing1.style.transform = 'translate(calc(-50% - 120vw), calc(-50% - 120vh)) rotate(45deg) scale(0.3)';
                orbitalRing1.style.opacity = '0';
            }

            // Ring 2 — flings bottom-right
            const orbitalRing2 = document.querySelector('.orbital-ring--2');
            if (orbitalRing2) {
                orbitalRing2.style.transition = flingSpeed;
                orbitalRing2.style.transform = 'translate(calc(-50% + 120vw), calc(-50% + 120vh)) rotate(-30deg) scale(0.3)';
                orbitalRing2.style.opacity = '0';
            }

            // Dot — rockets off to the right
            const orbDot = hero.querySelector('.orbital-dot');
            if (orbDot) {
                orbDot.style.transition = flingSpeed;
                orbDot.style.transform = 'translate(calc(-50% + 150vw), -50%) scale(3)';
                orbDot.style.opacity = '0';
            }

            // Fade the whole hero to ensure clean exit
            hero.style.transition = 'opacity 0.4s 0.1s ease-in';
            hero.style.opacity = '0';

            // Navigate after scatter finishes
            setTimeout(() => {
                window.location.href = 'about-me.html';
            }, 450);
            return;
        }

        if (accelerationProgress > 0 || isAccelerating) {
            animationFrameId = requestAnimationFrame(updateAcceleration);
        } else {
            animationFrameId = null;
        }
    }

    if (hero) {
        // Prevent context menu to not interrupt long presses
        hero.addEventListener('contextmenu', (e) => {
            if (isAccelerating || accelerationProgress > 0) e.preventDefault();
        });

        const startAccelerate = (e) => {
            // Ignore if clicked on a link or nav element
            if (e.target.closest('a') || e.target.closest('button')) return;
            // Only start if it's left click or touch
            if (e.type === 'mousedown' && e.button !== 0) return;

            // Mark if this is a mobile device / touch input
            isTouchInput = e.type === 'touchstart';

            // Extract animations only once to prevent lag
            if (cachedAnims.length === 0) {
                elementsToAccelerate.forEach(el => {
                    cachedAnims.push(...el.getAnimations());
                });
            }

            isAccelerating = true;
            lastVibrateTime = performance.now();
            if (!animationFrameId) requestAnimationFrame(updateAcceleration);
        };

        const stopAccelerate = () => {
            isAccelerating = false;
        };

        hero.addEventListener('mousedown', startAccelerate);
        window.addEventListener('mouseup', stopAccelerate);
        hero.addEventListener('mouseleave', stopAccelerate);

        let touchStartX = 0;
        let touchStartY = 0;

        hero.addEventListener('touchstart', (e) => {
            if (e.touches.length > 0) {
                touchStartX = e.touches[0].clientX;
                touchStartY = e.touches[0].clientY;
            }
            startAccelerate(e);
        }, { passive: true });

        hero.addEventListener('touchmove', (e) => {
            if (!isAccelerating || e.touches.length === 0) return;
            // Cancel if the finger moves more than 10 pixels (scrolling)
            const dx = e.touches[0].clientX - touchStartX;
            const dy = e.touches[0].clientY - touchStartY;
            if (Math.abs(dx) > 10 || Math.abs(dy) > 10) {
                stopAccelerate();
            }
        }, { passive: true });

        window.addEventListener('touchend', stopAccelerate);
        window.addEventListener('touchcancel', stopAccelerate);
        window.addEventListener('scroll', stopAccelerate, { passive: true });

        // Cleanup on Back-Forward Cache (bfcache) restore
        window.addEventListener('pageshow', (e) => {
            transitioning = false;
            isAccelerating = false;
            accelerationProgress = 0;

            // Reset hero opacity
            if (hero) {
                hero.style.transition = '';
                hero.style.opacity = '';
            }

            // Reset hero element styles
            const heroChildren = hero ? hero.querySelectorAll('.hero__content, .hero__nav, .hero__scroll-hint') : [];
            heroChildren.forEach(el => {
                el.style.transition = '';
                el.style.transform = '';
                el.style.opacity = '';
                el.style.filter = '';
            });

            // Reset orbital ring styles
            orbitalRings.forEach(ring => {
                ring.style.transition = '';
                ring.style.transform = '';
                ring.style.opacity = '';
            });

            // Reset orbital dot
            const orbDot = hero ? hero.querySelector('.orbital-dot') : null;
            if (orbDot) {
                orbDot.style.transition = '';
                orbDot.style.transform = '';
                orbDot.style.opacity = '';
            }

            if (hero) hero.style.setProperty('--accel', 0);
            if (noiseOverlay) noiseOverlay.style.opacity = 0.03;

            cachedAnims.forEach(anim => {
                anim.playbackRate = 1;
            });
            cachedAnims = [];
            animationFrameId = null;
        });
    }

    // ═══════════════════════════════════════
    // Smooth Scroll for nav links (manual rAF fallback)
    // ═══════════════════════════════════════
    function smoothScrollTo(targetY, duration) {
        const startY = window.pageYOffset;
        const diff = targetY - startY;
        let startTime = null;

        function easeInOutCubic(t) {
            return t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2;
        }

        function step(timestamp) {
            if (!startTime) startTime = timestamp;
            const elapsed = timestamp - startTime;
            const progress = Math.min(elapsed / duration, 1);
            window.scrollTo(0, startY + diff * easeInOutCubic(progress));
            if (progress < 1) {
                requestAnimationFrame(step);
            }
        }

        requestAnimationFrame(step);
    }

    document.querySelectorAll('.nav-link[data-section]').forEach(link => {
        link.addEventListener('click', (e) => {
            e.preventDefault();
            const targetId = link.getAttribute('data-section');
            const target = document.getElementById(targetId);
            if (target) {
                smoothScrollTo(target.offsetTop, 800);
            }
        });
    });

    // ═══════════════════════════════════════
    // Share Buttons
    // ═══════════════════════════════════════
    const shareLinkBtn = document.getElementById('share-link');
    if (shareLinkBtn) {
        shareLinkBtn.addEventListener('click', (e) => {
            e.preventDefault();
            navigator.clipboard.writeText(window.location.href).then(() => {
                showToast('Link copied to clipboard');
            }).catch(() => {
                showToast('Failed to copy link');
            });
        });
    }

    const shareTwitterBtn = document.getElementById('share-twitter');
    if (shareTwitterBtn) {
        shareTwitterBtn.addEventListener('click', (e) => {
            e.preventDefault();
            const text = encodeURIComponent(document.title);
            const url = encodeURIComponent(window.location.href);
            window.open(`https://twitter.com/intent/tweet?text=${text}&url=${url}`, '_blank', 'noopener,noreferrer');
        });
    }
});
