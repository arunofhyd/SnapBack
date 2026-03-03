        // Interactive Demo Script
        document.addEventListener('DOMContentLoaded', () => {
            const windows = document.querySelectorAll('.demo-window');
            const container = document.getElementById('demo-container');
            const saveBtn = document.getElementById('demo-save-btn');
            const restoreBtn = document.getElementById('demo-restore-btn');
            const dockIcons = document.querySelectorAll('.dock-icon');

            if (!container || !saveBtn || !restoreBtn) return;

            // State
            let savedState = {};
            let isDragging = false;
            let isResizing = false;
            let activeElement = null;
            let startX, startY, initialLeft, initialTop, initialWidth, initialHeight;
            let zIndexCounter = 20;

            // Helper: Bring window to front
            function bringToFront(win) {
                zIndexCounter++;
                win.style.zIndex = zIndexCounter;
            }

            // Helper: Update Dock Dot
            function updateDockDot(winId, isVisible) {
                const dot = document.getElementById(`dot-${winId}`);
                if (dot) dot.style.opacity = isVisible ? '1' : '0';
            }

            // 0. Mobile Adjustment (Initial Layout)
            function adjustForMobile() {
                if (window.innerWidth < 640) {
                    // Stagger windows vertically for mobile
                    const win1 = document.getElementById('win1');
                    const win2 = document.getElementById('win2');
                    const win3 = document.getElementById('win3');

                    if(win1) { win1.style.top = '10px'; win1.style.left = '10px'; }
                    if(win2) { win2.style.top = '80px'; win2.style.left = '30px'; }
                    if(win3) { win3.style.top = '150px'; win3.style.left = '50px'; }
                }
            }
            adjustForMobile();

            // 1. Save Logic
            function saveCurrentState() {
                windows.forEach(win => {
                    const style = window.getComputedStyle(win);
                    savedState[win.id] = {
                        top: win.style.top,
                        left: win.style.left,
                        width: win.style.width,
                        height: win.style.height,
                        display: win.style.display || 'flex' // default is flex
                    };
                });
            }
            // Save initial state immediately (after mobile adjustment)
            saveCurrentState();

            // 2. Window Interactions (Drag, Resize, Close)
            windows.forEach(win => {
                // Global click to bring to front
                const focusWindow = () => bringToFront(win);
                win.addEventListener('mousedown', focusWindow);
                win.addEventListener('touchstart', focusWindow, { passive: true });

                const header = win.querySelector('.window-header');
                const closeBtn = win.querySelector('.win-close');
                const minBtn = win.querySelector('.win-minimize');
                const maxBtn = win.querySelector('.win-maximize');
                const resizeHandle = win.querySelector('.resize-handle');

                // Close Button
                const closeWindow = (e) => {
                    e.stopPropagation();
                    if (e.cancelable) e.preventDefault();
                    win.style.display = 'none';
                    updateDockDot(win.id, false);
                };
                closeBtn.addEventListener('mousedown', closeWindow);
                closeBtn.addEventListener('touchstart', closeWindow, { passive: false });

                // Minimize Button
                if (minBtn) {
                    minBtn.addEventListener('mousedown', closeWindow); // Same behavior as close for demo
                    minBtn.addEventListener('touchstart', closeWindow, { passive: false });
                }

                // Maximize Button
                if (maxBtn) {
                    const toggleMaximize = (e) => {
                        e.stopPropagation();
                        if (e.cancelable) e.preventDefault();

                        bringToFront(win);

                        if (win.classList.contains('maximized')) {
                            // Restore
                            win.classList.remove('maximized');
                            const saved = win.dataset.preMaxState ? JSON.parse(win.dataset.preMaxState) : null;
                            if (saved) {
                                win.style.top = saved.top;
                                win.style.left = saved.left;
                                win.style.width = saved.width;
                                win.style.height = saved.height;
                            }
                        } else {
                            // Maximize
                            const style = window.getComputedStyle(win);
                            win.dataset.preMaxState = JSON.stringify({
                                top: win.style.top || style.top,
                                left: win.style.left || style.left,
                                width: win.style.width || style.width,
                                height: win.style.height || style.height
                            });

                            win.classList.add('maximized');
                            win.style.top = '0';
                            win.style.left = '0';
                            win.style.width = '100%';
                            win.style.height = '100%';
                        }
                    };
                    maxBtn.addEventListener('mousedown', toggleMaximize);
                    maxBtn.addEventListener('touchstart', toggleMaximize, { passive: false });
                }

                // Drag Start (Header only)
                const startDrag = (e) => {
                    if (e.target.classList.contains('win-close')) return;

                    isDragging = true;
                    activeElement = win;
                    bringToFront(win);
                    win.style.transition = 'none';

                    const clientX = e.touches ? e.touches[0].clientX : e.clientX;
                    const clientY = e.touches ? e.touches[0].clientY : e.clientY;

                    startX = clientX;
                    startY = clientY;

                    const style = window.getComputedStyle(win);
                    initialLeft = parseInt(style.left, 10) || 0;
                    initialTop = parseInt(style.top, 10) || 0;

                    if (e.cancelable) e.preventDefault();
                };
                header.addEventListener('mousedown', startDrag);
                header.addEventListener('touchstart', startDrag, { passive: false });

                // Resize Start
                if (resizeHandle) {
                    const startResize = (e) => {
                        e.stopPropagation();
                        isResizing = true;
                        activeElement = win;
                        bringToFront(win);
                        win.style.transition = 'none';

                        const clientX = e.touches ? e.touches[0].clientX : e.clientX;
                        const clientY = e.touches ? e.touches[0].clientY : e.clientY;

                        startX = clientX;
                        startY = clientY;

                        const style = window.getComputedStyle(win);
                        initialWidth = parseInt(style.width, 10) || 100;
                        initialHeight = parseInt(style.height, 10) || 100;

                        if (e.cancelable) e.preventDefault();
                    };
                    resizeHandle.addEventListener('mousedown', startResize);
                    resizeHandle.addEventListener('touchstart', startResize, { passive: false });
                }
            });

            // Global Move (Drag & Resize)
            const handleMove = (e) => {
                if (!activeElement) return;

                const clientX = e.touches ? e.touches[0].clientX : e.clientX;
                const clientY = e.touches ? e.touches[0].clientY : e.clientY;

                const dx = clientX - startX;
                const dy = clientY - startY;

                if (isDragging) {
                    let newLeft = initialLeft + dx;
                    let newTop = initialTop + dy;
                    activeElement.style.left = `${newLeft}px`;
                    activeElement.style.top = `${newTop}px`;
                } else if (isResizing) {
                    let newWidth = Math.max(80, initialWidth + dx);
                    let newHeight = Math.max(60, initialHeight + dy);
                    activeElement.style.width = `${newWidth}px`;
                    activeElement.style.height = `${newHeight}px`;
                }

                if (e.cancelable) e.preventDefault(); // Prevent scrolling on mobile
            };
            document.addEventListener('mousemove', handleMove);
            document.addEventListener('touchmove', handleMove, { passive: false });

            // Global Up
            const handleUp = () => {
                if (activeElement) {
                    activeElement.style.transition = 'all 0.5s cubic-bezier(0.25, 0.8, 0.25, 1)';
                    activeElement = null;
                }
                isDragging = false;
                isResizing = false;
            };
            document.addEventListener('mouseup', handleUp);
            document.addEventListener('touchend', handleUp);

            // 3. Dock Interactions
            dockIcons.forEach(icon => {
                icon.addEventListener('click', () => {
                    const targetId = icon.getAttribute('data-target');
                    const targetWin = document.getElementById(targetId);
                    if (targetWin) {
                        // Toggle logic: If visible and top, hide (minimize). Else show and bring to front.
                        const isVisible = targetWin.style.display !== 'none';
                        const isTop = targetWin.style.zIndex == 20;

                        if (isVisible && isTop) {
                            // Minimize (optional feature, strictly "launch" requested but toggle is nicer)
                             // targetWin.style.display = 'none';
                             // updateDockDot(targetId, false);
                             // Actually, let's just make it "Launch/Focus" to avoid confusion.
                             // If it's already there, just shake it or something?
                             // Let's stick to "Launch if closed, Focus if open".
                             bringToFront(targetWin);
                        } else {
                            targetWin.style.display = 'flex';
                            updateDockDot(targetId, true);
                            bringToFront(targetWin);

                            // Reset position if off-screen (safety)
                            const style = window.getComputedStyle(targetWin);
                            if (style.display === 'none') { // wait, we just set it to flex
                                // Check coords? Nah, keep it simple.
                            }
                        }
                    }
                });
            });

            // 4. Save Button
            saveBtn.addEventListener('click', () => {
                saveCurrentState();

                // Visual Feedback
                const originalText = saveBtn.innerText;
                saveBtn.innerText = "Saved!";
                saveBtn.classList.add('text-neon-cyan');
                setTimeout(() => {
                    saveBtn.innerText = originalText;
                    saveBtn.classList.remove('text-neon-cyan');
                }, 1000);
            });

            // 5. Restore Button
            restoreBtn.addEventListener('click', () => {
                // Create Magical Overlay
                const overlay = document.createElement('div');
                overlay.className = 'snapback-overlay';

                const text = document.createElement('div');
                text.className = 'snapback-text';
                text.textContent = 'Snap Back';

                overlay.appendChild(text);
                container.appendChild(overlay);

                // Trigger reflow to ensure transition works
                void overlay.offsetWidth;
                overlay.classList.add('active');

                // Delay restoration to let animation play
                setTimeout(() => {
                    windows.forEach(win => {
                        const state = savedState[win.id];
                        if (state) {
                            win.style.left = state.left;
                            win.style.top = state.top;
                            win.style.width = state.width;
                            win.style.height = state.height;
                            win.style.display = state.display;
                            updateDockDot(win.id, state.display !== 'none');

                            // Ensure window pops back nicely if it was minimized
                            if (state.display !== 'none') {
                                bringToFront(win);
                            }
                        }
                    });

                    // Flash container
                    const originalShadow = container.style.boxShadow;
                    container.style.boxShadow = "0 0 20px rgba(0, 255, 255, 0.3)";
                    container.style.borderColor = "rgba(0, 255, 255, 0.5)";
                    setTimeout(() => {
                        container.style.boxShadow = originalShadow;
                        container.style.borderColor = "";
                    }, 300);

                }, 150); // Restore windows almost instantly while text pops

                // Remove overlay after animation completes
                setTimeout(() => {
                    overlay.classList.remove('active');
                    setTimeout(() => {
                        if(container.contains(overlay)) {
                            container.removeChild(overlay);
                        }
                    }, 200); // Wait for fade out
                }, 600);
            });
        });
