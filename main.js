window.addEventListener('DOMContentLoaded', () => {
    AssetLoader.init();
    
    let loadedCount = 0;
    const criticalAssets = AssetLoader.registry.slice(0, 2);
    
    criticalAssets.forEach(src => {
        const img = new Image();
        img.src = src;
        img.onload = () => {
            loadedCount++;
            document.getElementById('load-perc').innerText = Math.round((loadedCount / criticalAssets.length) * 100) + '%';
            if (loadedCount === criticalAssets.length) {
                document.getElementById('loading-screen').style.display = 'none';
                document.getElementById('content-root').style.display = 'block';
                document.getElementById('bg-audio').play().catch(() => {});
            }
        };
    });
});