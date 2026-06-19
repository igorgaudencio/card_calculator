const calculatorForm = document.querySelector("#calculator-form");
const rangeForm = document.querySelector("#range-form");
const singleResult = document.querySelector("#single-result");
const rangeBody = document.querySelector("#range-body");
const errorMessage = document.querySelector("#error-message");

function currentFormulaFields() {
  const data = new FormData(calculatorForm);

  return {
    floor: data.get("floor"),
    multiplier: data.get("multiplier"),
    exponent: data.get("exponent")
  };
}

function rangeFields() {
  const data = new FormData(rangeForm);

  return {
    start_floor: data.get("start_floor"),
    end_floor: data.get("end_floor")
  };
}

function buildQuery() {
  return new URLSearchParams({
    ...currentFormulaFields(),
    ...rangeFields()
  });
}

async function calculate() {
  const response = await fetch(`/calculate?${buildQuery().toString()}`);
  const payload = await response.json();

  if (!response.ok) {
    throw new Error(payload.error || "Nao foi possivel calcular.");
  }

  return payload;
}

function showError(message) {
  errorMessage.hidden = false;
  errorMessage.textContent = message;
}

function clearError() {
  errorMessage.hidden = true;
  errorMessage.textContent = "";
}

function renderSingle(single) {
  singleResult.innerHTML = `
    <span class="result-label">Cartas geradas no floor ${single.floor}</span>
    <strong>${single.rounded.toLocaleString("pt-BR")}</strong>
    <span>Valor exato: ${single.exact.toLocaleString("pt-BR")}</span>
  `;
}

function renderRange(rows) {
  rangeBody.innerHTML = rows.map((row) => `
    <tr>
      <td>${row.floor.toLocaleString("pt-BR")}</td>
      <td>${row.rounded.toLocaleString("pt-BR")}</td>
      <td>${row.exact.toLocaleString("pt-BR")}</td>
    </tr>
  `).join("");
}

async function updateCalculator() {
  try {
    clearError();
    const payload = await calculate();
    renderSingle(payload.single);
    renderRange(payload.range);
  } catch (error) {
    showError(error.message);
  }
}

calculatorForm.addEventListener("submit", (event) => {
  event.preventDefault();
  updateCalculator();
});

rangeForm.addEventListener("submit", (event) => {
  event.preventDefault();
  updateCalculator();
});

updateCalculator();
