# Anime Card Battles X - Infinity Castle Card Drops

Calculadora web em Ruby para estimar cartas geradas por floor.

## Como rodar

```bash
ruby app.rb
```

Depois acesse:

```txt
http://localhost:4567
```

Para usar outra porta:

```bash
PORT=3000 ruby app.rb
```

## Formula atual

```txt
Cards = multiplicador * (Floor ^ expoente)
```

Valores padrao:

```txt
Multiplicador = 2.3
Expoente = 1.47
```

A formula fica concentrada em `app.rb`, na estrutura `Formula`, para facilitar alteracoes futuras.
