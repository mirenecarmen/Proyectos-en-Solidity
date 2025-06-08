# 🧾 SubastaTP2 - Contrato Solidity para Subasta de un Pase VIP

Este proyecto contiene el contrato inteligente `SubastaBadBunny` desarrollado en Solidity, que implementa una subasta segura y transparente para un **pase VIP al concierto de Bad Bunny en Buenos Aires (River Plate, 2026)**.

## 🚀 Características principales

- Subasta con tiempo de duración fijo (60 minutos)
- Extensión automática si hay ofertas en los últimos 10 minutos
- Comisión del 2% para un destinatario configurable
- Registro completo del historial de pujas
- Reembolso automático para postores superados
- Declaración del ganador al finalizar

---

## 🔧 Estructura del contrato

### 🔹 Datos principales de la subasta

| Variable               | Descripción                                                  |
|------------------------|--------------------------------------------------------------|
| `seller`               | Dirección del vendedor (quien despliega el contrato)         |
| `commissionReceiver`   | Dirección que recibe una comisión del 2%                     |
| `itemName`             | Nombre del ítem subastado                                    |
| `minimumBid`           | Oferta mínima requerida para participar                      |
| `auctionStart`         | Tiempo de inicio de la subasta                               |
| `auctionEnd`           | Tiempo de finalización de la subasta                         |
| `duration`             | Duración total (60 minutos por defecto)                      |
| `extensionTime`        | Tiempo adicional (10 minutos) si hay nuevas ofertas          |
| `commissionPercent`    | Porcentaje de comisión aplicado al monto final               |

---

### 🔹 Estructura de pujas

```solidity
struct Bid {
    address payable bidder;
    uint amount;
}

Las ofertas se almacenan en un array público bidHistory.
Las variables highestBidder y highestBid mantienen la mejor oferta actual.
Se utiliza un mapping refunds para que usuarios no ganadores puedan retirar sus fondos.

## ⚙️ Funcionalidades del contrato

🟢 placeBid()

Permite realizar una oferta válida:
Verifica que la subasta esté activa.
Exige que la nueva oferta supere al menos un 5% la actual.
Reembolsa al anterior mejor postor.
Registra la nueva oferta.
Extiende la subasta si la oferta llega en los últimos 10 minutos.

🟢 withdrawRefund()
Permite a los usuarios recuperar sus fondos si fueron superados. Sigue el patrón pull-over-push, evitando vulnerabilidades como ataques de reentrada.

🔴 finalizeAuction()
Finaliza la subasta:

Solo puede ejecutarse luego del tiempo de cierre.
Declara oficialmente al ganador.
Calcula y transfiere:
Comisión al commissionReceiver.
Resto del pago al seller.

## 👀 Funciones de consulta

getWinner(): Devuelve el ganador y la oferta más alta.
getBidHistory(): Devuelve el historial completo de pujas.

## 🛡️ Seguridad y buenas prácticas

Uso de modifiers para controlar cuándo se pueden ejecutar ciertas funciones.
Reembolsos protegidos mediante withdrawRefund().
Eventos NewBid y AuctionEnded para auditoría en la blockchain.
Validación de condiciones mínimas de puja y tiempo.