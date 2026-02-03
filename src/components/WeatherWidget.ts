import { fetchWeatherReadings } from '../api/weather';
import { formatCityTime } from '../utils/formatting';
import type { CityReading, Reading } from '../types';

// Use environment variable or fallback for local dev
const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000';

export function setupWeatherWidget(displayContainer: HTMLDivElement) {
  let isFetching = false;
  let latestData: CityReading[] | null = null;

  const renderTable = (data: CityReading[]) => {
    if (!data || data.length === 0) {
      displayContainer.innerHTML = '<p>No data loaded.</p>';
      return;
    }

    const rows = data.map(city => {
      const latest: Reading | undefined = city.readings[city.readings.length - 1];
      if (!latest) {
        return `<tr class="error-row">
          <td>${city.city}</td>
          <td>-</td>
          <td>-</td>
          <td>-</td>
        </tr>`;
      }
      return `
        <tr>
          <td>${city.city}</td>
          <td>${latest.tempC ?? '-'}</td>
          <td>${latest.tempF ?? '-'}</td>
          <td>${formatCityTime(latest.timezone)}</td>
        </tr>
      `;
    }).join('');

    const now = new Date();
    const formattedTime = now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' });

    displayContainer.innerHTML = `
      <table class="temp-table">
        <caption class="table-caption">Last updated: ${formattedTime}</caption>
        <thead>
          <tr><th>City</th><th>Temp (°C)</th><th>Temp (°F)</th><th>Local Time</th></tr>
        </thead>
        <tbody>${rows}</tbody>
      </table>
    `;

    const caption = displayContainer.querySelector('caption');
    if (caption) {
      (caption as HTMLElement).style.captionSide = 'bottom';
      (caption as HTMLElement).style.fontStyle = 'italic';
      (caption as HTMLElement).style.textAlign = 'center';
      (caption as HTMLElement).style.paddingTop = '8px';
    }
  };

  const fetchData = async () => {
    if (isFetching) return;
    isFetching = true;

    if (!displayContainer.innerHTML) {
      displayContainer.innerHTML = '<p class="loading-text">Fetching live data...</p>';
    }

    try {
      latestData = await fetchWeatherReadings();
    } catch (err) {
      const errorMsg = err instanceof Error ? err.message : 'Unknown error';
      
      // Handle specific authentication errors
      if (errorMsg.includes('API key') || errorMsg.includes('401') || errorMsg.includes('403')) {
        displayContainer.innerHTML = `
          <p style="color:red">Authentication Error: ${errorMsg}</p>
          <p style="color:orange; font-size:0.9em;">Check your API key configuration in .env.local</p>
        `;
      } else if (errorMsg.includes('CORS') || errorMsg.includes('404')) {
        displayContainer.innerHTML = `
          <p style="color:red">Connection Error: ${errorMsg}</p>
          <p style="color:orange; font-size:0.9em;">Make sure the backend server is running on ${API_BASE_URL}</p>
        `;
      } else {
        displayContainer.innerHTML = `<p style="color:red">Error: ${errorMsg}</p>`;
      }
    } finally {
      isFetching = false;
    }
  };

  // --- CLOCK-ALIGNED RENDER ---
  function scheduleRender() {
    const now = new Date();
    const delay = (60 - now.getSeconds()) * 1000 - now.getMilliseconds();

    setTimeout(function tick() {
      if (latestData) renderTable(latestData);
      setTimeout(tick, 60_000); // schedule next minute render
    }, delay);
  }

  // --- PREFETCH SCHEDULER (fetch ~10s early) ---
  const PREFETCH_MS = 10_000;

  function nextPrefetchTime(): number {
    const now = new Date();
    const next = new Date(now);
    next.setSeconds(0, 0);
    next.setMinutes(now.getMinutes() + 1);
    return next.getTime() - PREFETCH_MS;
  }

  function schedulePrefetch(targetTime?: number) {
    const nextTime = targetTime ?? nextPrefetchTime();
    const delay = Math.max(0, nextTime - Date.now());

    setTimeout(() => {
      fetchData(); // fetch early so data is ready by minute boundary
      schedulePrefetch(nextTime + 60_000); // schedule next prefetch
    }, delay);
  }

  // --- STARTUP ---
  fetchData();       // initial prefetch
  schedulePrefetch(); // recursive prefetching
  scheduleRender();   // clock-aligned rendering
}
