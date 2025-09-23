// /static/js/ruche_detail_chart.js
(function () {
    const el = document.getElementById('tempHumChart');
    if (!el) {
        console.warn('[chart] <canvas id="tempHumChart"> introuvable.');
        return;
    }

    // 1) Vérifier que les données sont bien là
    const raw = Array.isArray(window.CHART_POINTS) ? window.CHART_POINTS : [];
    console.log('[chart] CHART_POINTS count =', raw.length);
    console.log('[chart] first 3 =', raw.slice(0, 3));

    if (raw.length === 0) {
        console.warn('[chart] Aucune donnée à tracer.');
        return;
    }

    // 2) Construire les tableaux + convertir en nombres
    const labels = [];
    const temps  = [];
    const hums   = [];

    for (const p of raw) {
        const label = p.key ?? p.label ?? ''; // supporte les deux variantes
        const t = p.temperature ?? p.t ?? null;
        const h = p.humidity ?? p.h ?? null;

        const tNum = (t === null || t === undefined || t === '') ? null : Number(t);
        const hNum = (h === null || h === undefined || h === '') ? null : Number(h);

        labels.push(String(label));
        temps.push(Number.isFinite(tNum) ? tNum : null);
        hums.push(Number.isFinite(hNum) ? hNum : null);
    }

    console.log('[chart] labels sample:', labels.slice(0, 5));
    console.log('[chart] temps sample:', temps.slice(0, 5));
    console.log('[chart] hums  sample:', hums.slice(0, 5));

    // 3) Si toutes les temp sont nulles, pas la peine d’afficher une courbe “vide”
    const allTempNull = temps.every(v => v === null);
    const allHumNull  = hums.every(v => v === null);
    if (allTempNull && allHumNull) {
        console.warn('[chart] Toutes les valeurs sont nulles → rien à tracer.');
        return;
    }

    // 4) S'assurer que le canvas a une vraie hauteur
    // (max-height ne suffit pas toujours selon le CSS)
    el.height = 360; // px

    // 5) Créer le graphique
    // (si tu as un thème dark, tu peux décommenter borderColor)
    new Chart(el, {
        type: 'line',
        data: {
            labels,
            datasets: [
                {
                    label: 'Température (°C)',
                    data: temps,
                    spanGaps: true,
                    tension: 0.2,
                    pointRadius: 2,
                    borderWidth: 2,
                    // borderColor: '#ffcc00'
                },
                {
                    label: 'Humidité (%)',
                    data: hums,
                    spanGaps: true,
                    tension: 0.2,
                    pointRadius: 2,
                    borderWidth: 2,
                    yAxisID: 'y1',
                    // borderColor: '#66ccff'
                }
            ]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false, // puisque on fixe el.height
            interaction: { mode: 'nearest', intersect: false },
            scales: {
                x:  { title: { display: true, text: 'Horodatage (clé)' }, ticks: { autoSkip: true, maxRotation: 0 } },
                y:  { title: { display: true, text: 'Température (°C)' } },
                y1: { position: 'right', title: { display: true, text: 'Humidité (%)' }, grid: { drawOnChartArea: false } }
            }
        }
    });
})();
