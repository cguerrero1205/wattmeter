# Wattmeter — Medidor de potencia AC con PIC18F4550 y MATLAB

Medidor de energía monofásico que muestrea voltaje y corriente AC con un
**PIC18F4550**, envía las formas de onda por **USB (CDC / puerto COM virtual)**
y las grafica en una interfaz de **MATLAB (GUIDE)**, que calcula:

- Voltaje RMS (V) y corriente RMS (A)
- Potencia real (W), aparente (VA) y reactiva (VAR)
- Factor de potencia
- Energía consumida (kWh) y tiempo de consumo (min)

## Estructura del repositorio

```
wattmeter/
├── firmware/                 Código del microcontrolador (CCS C)
│   ├── wattmeter.c           Programa principal: muestreo, procesamiento y envío USB
│   ├── Flex_LCD420.c         Driver para LCD 20x4 (modo 4 bits)
│   └── usb_desc_cdc.h        Descriptores USB CDC (VID 0x04D8 / PID 0x000A)
└── software/
    └── matlab/               Interfaz gráfica de escritorio
        ├── Grafica.m         Lógica de la GUI (conexión serial, gráficas, cálculos)
        └── Grafica.fig       Diseño de la GUI (GUIDE)
```

> Los tres archivos de `firmware/` deben permanecer en la misma carpeta:
> `wattmeter.c` incluye `Flex_LCD420.c` y el `usb_desc_cdc.h` local
> reemplaza al que trae el compilador.

## Hardware

| Elemento              | Conexión                                   |
|-----------------------|--------------------------------------------|
| Microcontrolador      | PIC18F4550, cristal 20 MHz → 48 MHz (PLL)  |
| Sensor de voltaje AC  | AN0 (RA0), offset en 2.5 V                 |
| Sensor de corriente AC| AN1 (RA1), offset en 2.5 V                 |
| LCD 20x4              | D4–D7 → RB4–RB7, RS → RB1, E → RB2, RW → RE1 |
| LED RGB (ánodo común) | Azul RD5, Verde RD6, Rojo RD7              |
| Selección de modo     | RC0 / RC1 (LCD y/o USB)                    |
| Depuración            | RD1 conmuta en cada interrupción de TMR0   |

## Firmware

- Compilador: **CCS C (PCH)**. Usa `usb_cdc.h` y `usb_bootloader.h` del compilador.
- El TMR0 dispara el muestreo: **128 muestras por periodo**, acumuladas
  durante **30 periodos** para promediar.
- Se detecta el cruce por cero del voltaje, se alinean ambas señales y se
  corrige el desfase del sensor de corriente (`11.9666` muestras).
- Constantes de calibración en `procesar_resultados()`; definir `CALIB`
  para imprimir los cruces por cero en lugar de los datos.

Para compilar, abrir `firmware/wattmeter.c` en CCS C y grabar el `.hex`
resultante (con el bootloader USB o un programador).

## Software (MATLAB)

Requiere MATLAB con soporte para `serial` (probado con R2019a).

1. Conectar el medidor por USB e identificar el puerto COM en el
   Administrador de dispositivos.
2. En MATLAB, ir a `software/matlab/` y ejecutar `Grafica`.
3. Escribir el número de puerto, pulsar **Conectar** y luego **Graficar**.

## Protocolo de comunicación

Puerto COM virtual, 19200 baudios, 8N1, terminador `LF`.

| Comando (PC → PIC) | Acción                                       |
|--------------------|----------------------------------------------|
| `C`                | Capturar 30 periodos y enviar un periodo procesado |
| `D`                | Desconectar (reinicia el PIC)                |
| `L` / `N`          | Activar / desactivar LCD (enviado por la GUI; el firmware actual no lo procesa) |

Respuesta a `C`: 128 pares de enteros de 6 dígitos con signo
(`%06Ld%06Ld`) seguidos de `\r\n`:

- Voltaje × 10 (V)
- Corriente × 1000 (A)

## Autor

Carlos Guerrero
