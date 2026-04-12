const AssetLoader = {
    registry: [
        'assets/image.jpg', 'assets/1000128771.jpg', 'assets/1000128776.jpg',
        'assets/be2d65a4-3fa5-4312-976a-6f5cd913faaa.png', 'assets/732c8098-5c1e-4e22-aa2b-975f1c706661.png'
    ],
    init() {
        const observer = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    this.loadCard(entry.target);
                    observer.unobserve(entry.target);
                }
            });
        }, { threshold: 0.1 });
        this.registry.forEach(path => {
            const card = this.createPlaceholder(path);
            document.getElementById('gallery').appendChild(card);
            observer.observe(card);
        });
    },
    createPlaceholder(path) {
        const div = document.createElement('div');
        div.className = 'card';
        div.dataset.src = path;
        return div;
    },
    loadCard(el) {
        const img = new Image();
        img.src = el.dataset.src;
        img.onload = () => {
            el.appendChild(img);
            el.classList.add('visible');
        };
    }
};