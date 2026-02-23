import './style.css'
import { setupWeatherWidget } from './components/WeatherWidget'

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
      <p>Graph section coming soon...</p>
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
