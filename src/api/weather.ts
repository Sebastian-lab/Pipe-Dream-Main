import type { CityReading } from '../types';

// Use environment variable or fallback for local dev
const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:8000';
const API_KEY = import.meta.env.VITE_API_KEY || '';

export async function fetchWeatherReadings(): Promise<CityReading[]> {
  const response = await fetch(`${API_BASE_URL}/api/weather`, {
    method: 'GET',
    headers: {
      'Content-Type': 'application/json',
      'X-API-Key': API_KEY,
    },
  });
  
  if (!response.ok) {
    const errorMessage = await getErrorMessage(response);
    throw new Error(errorMessage);
  }

  return response.json();
}

export async function fetchWeatherHistory(): Promise<any> {
  const response = await fetch(`${API_BASE_URL}/api/weather/history`, {
    method: 'GET',
    headers: {
      'Content-Type': 'application/json',
      'X-API-Key': API_KEY,
    },
  });
  
  if (!response.ok) {
    const errorMessage = await getErrorMessage(response);
    throw new Error(errorMessage);
  }

  return response.json();
}

async function getErrorMessage(response: Response): Promise<string> {
  try {
    const errorData = await response.json();
    return errorData.detail || `HTTP ${response.status}: ${response.statusText}`;
  } catch {
    return `HTTP ${response.status}: ${response.statusText}`;
  }
}
