export function formatCityTime(timezone?: string): string {
  if (!timezone) return "Unknown";
  
  return new Date().toLocaleTimeString('en-US', {
    timeZone: timezone, 
    hour: '2-digit', 
    minute: '2-digit',
    hour12: true,
    timeZoneName: 'short'
  });
}
