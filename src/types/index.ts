export interface CityReading {
  id: number;
  city: string;
  tempF: number | null;
  tempC: number | null;
  timezone?: string;
  localTime: string;
  error?: string;
}
