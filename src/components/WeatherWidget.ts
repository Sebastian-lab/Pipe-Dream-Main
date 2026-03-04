import { fetchWeatherHistory, fetchWeatherReadings } from '../api/weather';
import type { CityReading } from '../types';

const API_BASE_URL = import.meta.env.VITE_API_URL || '/api';

export function setupWeatherWidget(displayContainer: HTMLDivElement) {
  let isFetching = false;
  let latestData: CityReading[] | null = null;

  const renderTable = (data: CityReading[]) => {
    if (!data || data.length === 0) {
      displayContainer.innerHTML = '<p>No data loaded.</p>';
      return;
    }

    const rows = data.map(city => {
      const localTimestamp = city.features?.[0] ?? null;
      const tempC = city.features?.[1] ?? null;
      const tempF = city.features?.[2] ?? null;
      const timezone = city.timezone;
      
      if (!localTimestamp || tempC === null || tempF === null) {
        return `<tr class="error-row">
          <td>${city.city}</td>
          <td>-</td>
          <td>-</td>
          <td>-</td>
        </tr>`;
      }
      
      const offsetMatch = localTimestamp.match(/([+-]\d{2}:\d{2})$/);
      let offsetStr = '';
      if (offsetMatch) {
        const offset = offsetMatch[1];
        const sign = offset[0];
        const hours = offset.slice(1, 3);
        offsetStr = ` UTC${sign}${hours}`;
      }
      
      const formattedTime = new Date(localTimestamp).toLocaleTimeString('en-US', {
          timeZone: timezone,
          hour: 'numeric',
          minute: '2-digit',
          hour12: true
        }) + offsetStr;
      
      return `
        <tr>
          <td>${city.city}</td>
          <td>${tempC}</td>
          <td>${tempF}</td>
          <td>${formattedTime}</td>
        </tr>
      `;
    }).join('');

    let formattedTime = "Unknown";

    const lastCity = data[data.length - 1];
    const lastLocalTimestamp = lastCity?.features?.[0] ?? null;

    if (lastLocalTimestamp) {
      const date = new Date(lastLocalTimestamp);
      if (!isNaN(date.getTime())) {
        formattedTime = date.toLocaleTimeString('en-US', {
          hour: 'numeric',
          minute: '2-digit',
          hour12: true
        });
      }
    }

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
      
      if (errorMsg.includes('API key') || errorMsg.includes('401') || errorMsg.includes('403')) {
        displayContainer.innerHTML = `
          <p style="color:red">Authentication Error: ${errorMsg}</p>
          <p style="color:orange; font-size:0.9em;">Check your API key configuration in .env</p>
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

  function scheduleRender() {
    const now = new Date();
    const delay = (60 - now.getSeconds()) * 1000 - now.getMilliseconds();

    setTimeout(function tick() {
      if (latestData) renderTable(latestData);
      setTimeout(tick, 60_000);
    }, delay);
  }

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
      fetchData();
      schedulePrefetch(nextTime + 60_000);
    }, delay);
  }

  async function loadHistory() {
    const history = await fetchWeatherHistory();
    renderTable(history);
  }

  loadHistory();
  fetchData();
  schedulePrefetch();
  scheduleRender();
}
