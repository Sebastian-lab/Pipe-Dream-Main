export interface CityReading {
  city: string;
  timestamp: string | null;
  features: [string, number | null, number | null] | null;
  timezone?: string;
}

export interface Prediction {
  _id: string;
  city: string;
  predictions: number[];
  timestamps: string[];
  model_file: string;
  created_at: string;
}
