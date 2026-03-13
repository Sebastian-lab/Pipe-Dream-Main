import './style.css'
import { setupWeatherWidget } from './components/WeatherWidget'
import { fetchPredictions } from './api/weather'
import type { Prediction } from './types'

type Tab = 'home' | 'chart' | 'graph' | 'report';

function showTab(tab: Tab) {
  document.querySelectorAll('.tab-btn').forEach(btn => {
    btn.classList.remove('active');
  });
  document.querySelectorAll('.tab-content').forEach(content => {
    (content as HTMLElement).style.display = 'none';
  });

  const activeBtn = document.querySelector(`[data-tab="${tab}"]`);
  const activeContent = document.getElementById(`${tab}-content`);

  if (activeBtn) activeBtn.classList.add('active');
  if (activeContent) (activeContent as HTMLElement).style.display = 'block';
}

document.querySelector<HTMLDivElement>('#app')!.innerHTML = `
  <div class="tabs-container">
    <div class="tab-buttons">
      <button class="tab-btn active" data-tab="home">Home</button>
      <button class="tab-btn" data-tab="chart">Chart</button>
      <button class="tab-btn" data-tab="graph">Graph</button>
      <button class="tab-btn" data-tab="report">Report</button>
    </div>
    
    <div id="home-content" class="tab-content">
      <div class="home-content">
        <h1>Pipe Dream</h1>
        <p class="description">A real-time weather monitoring system that tracks temperature readings from multiple cities around the world.</p>
      </div>
    </div>
    
    <div id="chart-content" class="tab-content" style="display: none;">
      <div id="table-container"></div>
    </div>
    
    <div id="graph-content" class="tab-content" style="display: none;">
      <div id="predictions-container">
        <div class="predictions-header">
          <label for="city-select">Select City: </label>
          <select id="city-select">
            <option value="">Loading cities...</option>
          </select>
        </div>
        <div id="predictions-table-container"></div>
      </div>
    </div>
    
    <div id="report-content" class="tab-content" style="display: none;">
      <p>Report section coming soon...</p>
    </div>
  </div>
`;

document.querySelectorAll('.tab-btn').forEach(btn => {
  btn.addEventListener('click', () => {
    const tab = btn.getAttribute('data-tab') as Tab;
    showTab(tab);
  });
});

setupWeatherWidget(
  document.querySelector<HTMLDivElement>('#table-container')!
);

let allPredictions: Prediction[] = [];

async function loadPredictions() {
  try {
    allPredictions = await fetchPredictions();
    const cities = [...new Set(allPredictions.map(p => p.city))];
    const select = document.getElementById('city-select') as HTMLSelectElement;
    select.innerHTML = cities.map(city => `<option value="${city}">${city}</option>`).join('');
    
    if (cities.length > 0) {
      renderPredictionsTable(cities[0]);
    }
    
    select.addEventListener('change', (e) => {
      const selectedCity = (e.target as HTMLSelectElement).value;
      if (selectedCity) {
        renderPredictionsTable(selectedCity);
      }
    });
  } catch (error) {
    console.error('Failed to load predictions:', error);
    const select = document.getElementById('city-select') as HTMLSelectElement;
    select.innerHTML = '<option value="">Failed to load</option>';
  }
}

function renderPredictionsTable(city: string) {
  const container = document.getElementById('predictions-table-container')!;
  const predictions = allPredictions.filter(p => p.city === city);
  
  if (predictions.length === 0) {
    container.innerHTML = '<p>No predictions found for this city.</p>';
    return;
  }
  
  const latestPred = predictions[0];
  
  let tableHTML = `
    <table class="predictions-table">
      <thead>
        <tr>
          <th>Prediction Value</th>
          <th>Timestamp</th>
        </tr>
      </thead>
      <tbody>
  `;
  
  latestPred.predictions.forEach((value, index) => {
    const timestamp = latestPred.timestamps[index] || 'N/A';
    tableHTML += `
      <tr>
        <td>${value.toFixed(4)}</td>
        <td>${timestamp}</td>
      </tr>
    `;
  });
  
  tableHTML += `
      </tbody>
    </table>
    <div class="predictions-meta">
      <p><strong>Model File:</strong> ${latestPred.model_file}</p>
      <p><strong>Created At:</strong> ${latestPred.created_at}</p>
    </div>
  `;
  
  container.innerHTML = tableHTML;
}

loadPredictions();
