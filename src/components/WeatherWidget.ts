import { fetchWeatherReadings } from '../api/weather';
import { formatCityTime } from '../utils/formatting';
import type { CityReading } from '../types';

export function setupWeatherWidget(
  triggerBtn: HTMLButtonElement,
  displayContainer: HTMLDivElement
) {
  
  const renderTable = (data: CityReading[]) => {
    if (data.length === 0) {
      displayContainer.innerHTML = '<p>No data loaded.</p>';
      return;
    }

    // Notice how clean this map is now that logic is extracted
    const rows = data.map(row => `
      <tr class="${row.error ? 'error-row' : ''}">
        <td>${row.city}</td>
        <td>${row.tempC ?? '-'}</td>
        <td>${row.tempF ?? '-'}</td>
        <td>${formatCityTime(row.timezone)}</td>
      </tr>
    `).join('');

    displayContainer.innerHTML = `
      <table class="temp-table">
        <thead>
          <tr><th>City</th><th>Temp (°C)</th><th>Temp (°F)</th><th>Local Time</th></tr>
        </thead>
        <tbody>${rows}</tbody>
      </table>
    `;
  };

  triggerBtn.addEventListener('click', async () => {
    triggerBtn.disabled = true;
    triggerBtn.textContent = "Loading...";
    displayContainer.innerHTML = '<p class="loading-text">Fetching live data...</p>';

    try {
      const data = await fetchWeatherReadings();
      renderTable(data);
    } catch (err) {
      displayContainer.innerHTML = `<p style="color:red">Error: ${err}</p>`;
    } finally {
      triggerBtn.disabled = false;
      triggerBtn.textContent = "Get Live Data";
    }
  });
}
