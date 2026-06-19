require "json"
require "socket"
require "uri"

Formula = Struct.new(:name, :multiplier, :exponent, keyword_init: true) do
  def calculate(floor)
    multiplier * (floor**exponent)
  end
end

DEFAULT_FORMULA = Formula.new(
  name: "Infinity Castle Card Drops",
  multiplier: 2.3,
  exponent: 1.47
)

def numeric_param(params, key, default: nil)
  value = params[key]&.first
  return default if value.nil? || value.strip.empty?

  Float(value)
rescue ArgumentError
  default
end

def integer_param(params, key, default: nil)
  value = params[key]&.first
  return default if value.nil? || value.strip.empty?

  Integer(value)
rescue ArgumentError
  default
end

def calculation_payload(params)
  multiplier = numeric_param(params, "multiplier", default: DEFAULT_FORMULA.multiplier)
  exponent = numeric_param(params, "exponent", default: DEFAULT_FORMULA.exponent)
  floor = integer_param(params, "floor", default: 1)
  start_floor = integer_param(params, "start_floor", default: 1)
  end_floor = integer_param(params, "end_floor", default: 100)

  raise ArgumentError, "O floor deve ser maior ou igual a 1." if floor < 1
  raise ArgumentError, "O floor inicial deve ser maior ou igual a 1." if start_floor < 1
  raise ArgumentError, "O floor final deve ser maior ou igual ao inicial." if end_floor < start_floor
  raise ArgumentError, "O intervalo deve ter no maximo 500 floors." if (end_floor - start_floor) > 499

  formula = Formula.new(
    name: DEFAULT_FORMULA.name,
    multiplier: multiplier,
    exponent: exponent
  )

  exact = formula.calculate(floor)
  range = (start_floor..end_floor).map do |current_floor|
    cards = formula.calculate(current_floor)
    {
      floor: current_floor,
      rounded: cards.round,
      exact: cards.round(4)
    }
  end

  {
    formula: {
      name: formula.name,
      multiplier: formula.multiplier,
      exponent: formula.exponent
    },
    single: {
      floor: floor,
      rounded: exact.round,
      exact: exact.round(4)
    },
    range: range
  }
end

def html_page
  <<~HTML
    <!doctype html>
    <html lang="pt-BR">
      <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>Anime Card Battles X - Card Drops</title>
        <link rel="stylesheet" href="/styles.css">
      </head>
      <body>
        <main class="shell">
          <section class="intro" aria-labelledby="page-title">
            <p class="eyebrow">Anime Card Battles X</p>
            <h1 id="page-title">Infinity Castle Card Drops</h1>
            <p>Calcule cartas geradas por floor usando a formula Cards = multiplicador * Floor ^ expoente.</p>
          </section>

          <section class="panel" aria-labelledby="single-title">
            <div class="panel-header">
              <div>
                <h2 id="single-title">Calculo individual</h2>
                <p>Use para descobrir a quantidade de cartas em um floor especifico.</p>
              </div>
            </div>

            <form id="calculator-form" class="form-grid">
              <label>
                Floor
                <input type="number" name="floor" min="1" step="1" value="10" required>
              </label>

              <label>
                Multiplicador base
                <input type="number" name="multiplier" min="0" step="0.01" value="2.3" required>
              </label>

              <label>
                Expoente
                <input type="number" name="exponent" min="0" step="0.01" value="1.47" required>
              </label>

              <button type="submit">Calcular</button>
            </form>

            <div id="single-result" class="result" aria-live="polite">
              <span class="result-label">Cartas geradas</span>
              <strong>0</strong>
              <span>Valor exato: 0</span>
            </div>
          </section>

          <section class="panel" aria-labelledby="range-title">
            <div class="panel-header">
              <div>
                <h2 id="range-title">Varios floors</h2>
                <p>Informe um intervalo para gerar a tabela de cartas por andar.</p>
              </div>
            </div>

            <form id="range-form" class="form-grid range-grid">
              <label>
                Floor inicial
                <input type="number" name="start_floor" min="1" step="1" value="1" required>
              </label>

              <label>
                Floor final
                <input type="number" name="end_floor" min="1" step="1" value="100" required>
              </label>

              <button type="submit">Gerar tabela</button>
            </form>

            <div id="error-message" class="error" role="alert" hidden></div>

            <div class="table-wrap">
              <table>
                <thead>
                  <tr>
                    <th>Floor</th>
                    <th>Cartas geradas</th>
                    <th>Valor exato</th>
                  </tr>
                </thead>
                <tbody id="range-body"></tbody>
              </table>
            </div>
          </section>
        </main>

        <script src="/app.js"></script>
      </body>
    </html>
  HTML
end

def file_response(path, content_type)
  return [404, "text/plain; charset=utf-8", "Arquivo nao encontrado."] unless File.file?(path)

  [200, content_type, File.read(path)]
end

def route(path, query)
  case path
  when "/"
    [200, "text/html; charset=utf-8", html_page]
  when "/calculate"
    begin
      [200, "application/json; charset=utf-8", JSON.generate(calculation_payload(query))]
    rescue ArgumentError => error
      [422, "application/json; charset=utf-8", JSON.generate(error: error.message)]
    end
  when "/styles.css"
    file_response(File.expand_path("public/styles.css", __dir__), "text/css; charset=utf-8")
  when "/app.js"
    file_response(File.expand_path("public/app.js", __dir__), "application/javascript; charset=utf-8")
  else
    [404, "text/plain; charset=utf-8", "Pagina nao encontrada."]
  end
end

port = ENV.fetch("PORT", 4567).to_i
server = TCPServer.new("127.0.0.1", port)
puts "Servidor rodando em http://localhost:#{port}"

trap("INT") do
  server.close
  exit
end

loop do
  client = server.accept
  request_line = client.gets
  next client.close if request_line.nil?

  method, target = request_line.split
  while (line = client.gets)
    break if line == "\r\n"
  end

  if method != "GET"
    status, content_type, body = [405, "text/plain; charset=utf-8", "Metodo nao permitido."]
  else
    uri = URI.parse(target)
    query = URI.decode_www_form(uri.query || "").group_by(&:first).transform_values { |pairs| pairs.map(&:last) }
    status, content_type, body = route(uri.path, query)
  end

  reason = {
    200 => "OK",
    404 => "Not Found",
    405 => "Method Not Allowed",
    422 => "Unprocessable Entity"
  }.fetch(status, "OK")

  client.write "HTTP/1.1 #{status} #{reason}\r\n"
  client.write "Content-Type: #{content_type}\r\n"
  client.write "Content-Length: #{body.bytesize}\r\n"
  client.write "Connection: close\r\n"
  client.write "\r\n"
  client.write body
ensure
  client&.close
end
