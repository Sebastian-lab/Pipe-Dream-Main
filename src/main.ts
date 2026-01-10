import './style.css'
import typescriptLogo from './typescript.svg'
import viteLogo from './vite.svg'
import { setupCounter } from './components/Counter'
import { setupWeatherWidget } from './components/WeatherWidget'

document.querySelector<HTMLDivElement>('#app')!.innerHTML = `
  <div>
    <a href="https://vite.dev" target="_blank">
      <img src="${viteLogo}" class="logo" alt="Vite logo" />
    </a>
    <a href="https://www.typescriptlang.org/" target="_blank">
      <img src="${typescriptLogo}" class="logo vanilla" alt="TypeScript logo" />
    </a>
    <h1>Pipe-Dream</h1>
    <div class="card">
      <button id="counter" type="button"></button>
      <button id="fetch-btn" type="button">Get Live Data</button>
    </div>
    <div id="table-container"></div>
  </div>
`

setupCounter(document.querySelector<HTMLButtonElement>('#counter')!)
setupWeatherWidget(
  document.querySelector<HTMLButtonElement>('#fetch-btn')!, 
  document.querySelector<HTMLDivElement>('#table-container')!
)
