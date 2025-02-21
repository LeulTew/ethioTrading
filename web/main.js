// Web launch configuration
if (typeof window !== 'undefined') {
    window.addEventListener('load', function() {
        // Prevent multiple instances
        if (window.opener) {
            window.close();
            return;
        }
    });
}