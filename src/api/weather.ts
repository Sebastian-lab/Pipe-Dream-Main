import type { CityReading } from '../types';

// Use environment variable or fallback for local dev
const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://0.0.0.0:8000';

export async function fetchWeatherReadings(): Promise<CityReading[]> {
  const response = await fetch(`${API_BASE_URL}/api/weather`);
  
  if (!response.ok) {
    throw new Error(`HTTP ${response.status}`);
  }

  return response.json();
}
