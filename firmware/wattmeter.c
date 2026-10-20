///////////////////////////////////////////////////////////////////////////////////////////////////
////
//// Sistema de comunicación SERIAL CDC entre PIC y PC
////
///////////////////////////////////////////////////////////////////////////////////////////////////
#include <18F4550.h> //PIC seleccionado
#device adc=10 //ADC a 10 bits
#fuses HSPLL,NOWDT,NOPROTECT,NOLVP,NODEBUG,USBDIV,PLL5,CPUDIV1,VREGEN,NOPBADEN,MCLR    //Configuracion de fuses
#use delay(clock=48000000) //Reloj configurado a 48MHz, el cristal es de 20MHz

// ***************************** LIBRERIAS *********************************
#include <usb_cdc.h>                            //Libreria que incluye los comandos de comunicacion CDC.
#include <math.h>                               //Libreria que sirva para realizar operaciones matematicas.
#include <Flex_LCD420.c>                        //Libreria para la LCD 2004
#include <usb_bootloader.h>

// ***************************** ABREVIACIONES *********************************
#define LED_AZUL PIN_D5                         //LED RGB de anodo comun, pin del LED azul
#define LED_VERDE PIN_D6                        //LED RGB de anodo comun, pin del LED verde (Indica estado conectado con la PC)
#define LED_ROJO PIN_D7                         //LED RGB de anodo comun, pin del LED azul  (Indica estado NO conectado con la PC)
#define apaga output_low                        //Pone en 0 un pin del PIC
#define enciende output_high                    //Pone en 1 un pin del PIC
#define conmuta output_toggle                   //Conmutar el estado de un pin del PIC
#define apagaRGB output_high                    //Pone en 1 el pin correspondiente del LED RGB
#define enciendeRGB  output_low                 //Pone en 0 el pin correspondiente del LED RGB
#define start_TMR0 enable_interrupts(INT_RTCC); //Inicia la interrupcion por TMR0
#define stop_TMR0 disable_interrupts(INT_RTCC); //Detiene la interrupcion por TMR0
#define clear_TMR0 clear_interrupt(INT_RTCC);   //Limpia las banderas y registros de TMR0
#define start_EXT enable_interrupts(INT_EXT);   //Inicia la interrupcion externa por RB0
#define stop_EXT disable_interrupts(INT_EXT);   //Detiene la interrupcion externa por RB0
#define clear_EXT clear_interrupt(INT_EXT);     //Limpia las banderas y registros de la interrupcion externa por RB0

// ************************ VARIABLES Y CONSTANTES *****************************
int1 datos_listos = 0;                          //Usada como bandera para indicar que los datos estan listos para ser procesados y enviados
int1 UsarLCD = 0;
int1 UsarCDC = 0;
const int8 SAMPLES_PERIOD = 128;                      //Cantidad de muestras por periodo
const int8 N_PERIOD = 30;                              //Periodos a muestrear
const int8 delay_TMR0 = 67;                           //Tiempo de desbordamiento del TMR0                        
int8 sample = 0;                                //Variable usada para determinar el numero de muestras tomadas
int8 period = 0;                                //Variable usada para determinar el numero de periodos muestreados
int16 adc;                                      //Variable usada para almacenar temporalmente el valor ADC de un sensor durante la lectura y envio de datos
char dato = 'P';
//Para almacenar los adc de los sensores AC
int8 tmp[768];
signed int16* V=(signed int16*)&tmp[0];
signed int16* I=(signed int16*)&tmp[256];//256
signed int16* T=(signed int16*)&tmp[512];//512

///////////////////////////////////////////////////////////////////////////////////////////////////
//
// INTERRUPCION TMR0
//
///////////////////////////////////////////////////////////////////////////////////////////////////

#int_RTCC                                       //Funcion que se ejecuta al entrar en interrupcion por desbordamiento de TMR0
void  RTCC_isr(void){                            //Inicia la toma de muestras  
   clear_TMR0                                   //Limpia las banderas y registros de TMR0
   set_timer0(delay_TMR0);                      //Establece el tiempo de desbordamiento de TMR0
   conmuta(PIN_D1);
   //Canal para la corriente AC                 //Toma la muestra del sensor de Iac
   set_adc_channel(1);                          //Selecciona el canal ADC 1 (RA1)
   delay_us(10);                                //Tiempo para que se estabilice el voltaje en el canal
   adc=read_adc();                              //Lee el voltaje en el canal y lo guarda en la variable "adc"
   adc -= 512;                                  //Resta el nivel de offset del sensor
   I[sample] += adc;                            //Suma y guarda el valor de "adc" promediado en la posicion del vector correspondiente
   
   //Canal para el voltaje AC                   //Toma la muestra del sensor de Vac
   set_adc_channel(0);                          //Selecciona el canal ADC 0 (RA0)
   delay_us(10);                                //Tiempo para que se estabilice el voltaje en el canal
   adc=read_adc();                              //Lee el voltaje en el canal y lo guarda en la variable "adc"
   adc -= 512;                                  //Resta el nivel de offset del sensor
   V[sample] += adc;                            //Suma y guarda el valor de "adc" promediado en la posicion del vector correspondiente
   sample++;                                    //Aumenta la variable "sample" en 1 (sample = sample + 1)
   if (sample==SAMPLES_PERIOD)                  //Tomó todas las muestras por periodo?
   {                                            //Si, entonces
      //conmuta(pin_D3);                          //Cambia el estado de RD3
      sample=0;                                 //Reestablece el valor de la variable
      period++;                                 //Aumenta la variable "period" en 1 (period = period + 1)
      if (period==N_PERIOD){                     //Tomó las muestras de todos los periodos?
      //Finaliza toma de datos 
         //conmuta(pin_D4);                       //Cambia el estado de RD4
         datos_listos = 1;                      //Los datos estan listos para ser procesados y enviados
         stop_TMR0                              //Detiene la interrupcion por TMR0
      }  
   }
   conmuta(PIN_D1);
}  // Finaliza toma de muestras

//#define CALIB


// Detects zero crossing (index + fraction)
float zero_crossing(signed int16* data){
   int8 k,kk;
   float frac;
   for(k=0;k<SAMPLES_PERIOD;k++){
      kk=k+1; kk&=(SAMPLES_PERIOD-1); 
      if ( (data[k]<=0) && (data[kk]>0) ) break;  // ZC in [k,k+1]
   }
   frac = (data[kk]-data[k]); if (frac==0) frac=0.5; else frac = -data[k]/frac; //Fraction within interval
   frac+=k;
   return frac;
}


void procesar_resultados(void){
   int8 k,kk,ZC;
   float frac;
   float zc1,zc2,dt;
   float Vrms,Irms,Preal,Prms,factor;
   float ii,vv;

   #ifdef CALIB 
   zc1=zero_crossing(V);
   zc2=zero_crossing(I);
   dt = zc2-zc1; if (dt<0) dt+=SAMPLES_PERIOD;
   printf(usb_cdc_putc,"%2.4f %2.4f %2.4f\r\n", zc1, zc2, dt);
   return;
   #endif 

   zc1=zero_crossing(V);
 
   //Reorganiza los valores de la corriente y voltaje
   //CORRIENTE
   zc2=zc1+11.9666; //11.9666
   if (zc2>=SAMPLES_PERIOD) zc2-=SAMPLES_PERIOD;
   ZC = (int8)zc2;  frac = zc2-ZC;
   for(k=0,kk=ZC;k<SAMPLES_PERIOD;k++,kk++){
      kk &= (SAMPLES_PERIOD-1);
      T[k]=I[kk];
      //printf(usb_cdc_putc,"%Ld, ", T[k]);
   } 
   //printf(usb_cdc_putc,"\r\n"); 
   for(k=0,kk=1;k<SAMPLES_PERIOD;k++,kk++){
      kk &= (SAMPLES_PERIOD-1);
      ii = (T[kk]-T[k]); ii*=frac; ii+=T[k];
      //ii=15.916*((ii/N_PERIOD)/1024)*5-0.0481; //ORIGINAL
      ii=14.916*((ii/N_PERIOD)/1024)*5-0.08;
      //printf(usb_cdc_putc,"%1.4f,", ii);
      I[k]=(signed int16)(ii*1000);
      //printf(usb_cdc_putc,"%Ld,", I[k]);
   } 
   //printf(usb_cdc_putc,"\r\n");
   
   //VOLTAJE
   if (zc1>=SAMPLES_PERIOD) zc1-=SAMPLES_PERIOD;
   ZC = (int8)zc1;  frac = zc1-ZC;
   for(k=0,kk=ZC;k<SAMPLES_PERIOD;k++,kk++){
      kk &= (SAMPLES_PERIOD-1);
      T[k]=V[kk];
      //printf(usb_cdc_putc,"%Ld, ", T[k]);
   } 
   //printf(usb_cdc_putc,"\r\n"); 
   for(k=0,kk=1;k<SAMPLES_PERIOD;k++,kk++){  // Interpolar el valor en I[k] entre I[k] y I[k+1] con frac
      kk &= (SAMPLES_PERIOD-1);
      ii = (T[kk]-T[k]); ii*=frac; ii+=T[k];
      //printf(usb_cdc_putc,"%3.0f, ",ii);
      ii=169.11*(((ii/N_PERIOD)/1023.0)*5)-1.8508;  //ORIGINAL
      V[k]=(signed int16)(ii*10);
      //printf(usb_cdc_putc,"%Ld, ",V[k]);
   }
   //printf(usb_cdc_putc,"\r\n"); 
   Preal=0;  Irms=0; Vrms=0;
   for(k=0;k<SAMPLES_PERIOD;k++){
      vv = ((float)V[k]/10.00);
      ii = ((float)I[k]/1000.00);
      Irms  += (ii*ii);
      Vrms  += (vv*vv);
      Preal += (ii*vv);
      //printf(usb_cdc_putc,"%3.0f,%3.0f\r\n", vv, ii); //Graficar
      printf(usb_cdc_putc,"%06Ld%06Ld", V[k], I[k]); //MATLAB
   }
   printf(usb_cdc_putc,"\r\n"); //MATLAB
   Irms=sqrt(Irms/SAMPLES_PERIOD);
   Preal=Preal/SAMPLES_PERIOD; 
   Vrms=sqrt(Vrms/SAMPLES_PERIOD);
   Prms = Vrms*Irms;  
   factor = Preal/Prms;

   if (Irms<0.1) { Irms=0.0; Prms=0.0; Preal=0.0; factor=0.0;}                
   //printf(usb_cdc_putc,"Vrms: %2.3f, Irms: %2.3f, Prms: %2.3f, Preal: %2.3f, Factor: %2.3f\r\n", Vrms, Irms, Prms, Preal, factor);
}


void reset_datos(void){
   int8 k;
   k=0; while(k<SAMPLES_PERIOD) { V[k]=0; I[k]=0; T[k]=0; k++;}
   period=0; datos_listos=0; sample=0; start_TMR0; dato = 'P';
}

void main(void){
   set_tris_B(0x01);
   set_tris_C(0x02);
   set_tris_D(0x00);
   output_LOW(PIN_D0);                               //Estado de interrupcion externa
   output_LOW(PIN_D1);                               //Estado de interrupcion de TMR0
   output_LOW(PIN_D2);                               //Conmuta al tomar 1 muestra de  todos los canales
   output_LOW(PIN_D3);                               //Conmuta al tomar las n muestras de 1 periodo de los canales ADC
   output_LOW(PIN_D4);                               //Conmuta al terminar el muestreo de los n periodos
   output_HIGH(LED_AZUL);                          //Apaga el LED azul RGB
   output_HIGH(LED_VERDE);                         //Apaga el LED verde RGB
   output_LOW(LED_ROJO);                       //Enciende el LED rojo RGB
   port_b_pullups(TRUE);                        //Resistencias Pullups activadas
   setup_adc_ports(AN0_TO_AN3|VSS_VDD);         //Puertos ADC activos de AN0 - AN3, voltaje de referencia los de la fuente (5v - 0v)
   setup_adc(ADC_CLOCK_INTERNAL);               //Reloj para ADC, usar reloj interno
   setup_psp(PSP_DISABLED);                     //Comunicacion PSP deshabilitada
   setup_spi(SPI_SS_DISABLED);                  //Comunicacion SPI deshabilitada
   setup_wdt(WDT_OFF);                          //WDT dehsabilitado
   setup_timer_0(RTCC_INTERNAL|RTCC_DIV_8|RTCC_8_bit);   //TMR0 activado, prescaler de 8 y usarlo a 8 bits
   setup_timer_1(T1_DISABLED);                  //TMR1 deshabilitado
   setup_timer_2(T2_DISABLED,0,1);              //TMR2 deshabilitado
   setup_timer_3(T3_DISABLED|T3_DIV_BY_1);      //TMR3 deshabilitado
   setup_comparator(NC_NC_NC_NC);               //Comparadores deshabilitados                   
   clear_TMR0                                   //Limpia las banderas y registros de TMR0
   set_timer0 (delay_TMR0);                     //Establece el tiempo de desbordamiento de TMR0
   delay_ms(100);                               //Retardo para estabilizar el sistema
   enable_interrupts(global);                   //Habilita las interrupciones globales
   stop_TMR0
   lcd_init();                                  //Inicia LCD
   if((input(PIN_C0) == 1)&&(input(PIN_C1)==1)){UsarLCD = 1; UsarCDC = 1;} 
   else if((input(PIN_C0)==0)&&(input(PIN_C1)==1)){UsarLCD = 1; UsarCDC = 0;}
      else if((input(PIN_C0)==1)&&(input(PIN_C1)==0)){UsarLCD = 0; UsarCDC = 1;}
   if(UsarLCD == 1){
      printf(lcd_putc, "\f\nVrms:     Irms: ");     //Muestra en la LCD
      printf(lcd_putc, "\n       CONEXION");       //Muestra en la LCD
      printf(lcd_putc, "\f  DESARROLLADO POR");    //Muestra en la LCD
      printf(lcd_putc, "\n  CARLOS  GUERRERO");    //Muestra en la LCD
      lcd_gotoxy(5,4);                             //Posicion en la LCD (X, Y)
      printf(lcd_putc, "DESCONECTADO");            //Muestra en la LCD
   }
   else{
      usb_cdc_init();                              //Inicia comunicacion CDC
      usb_init();                                  //Inicia USB
      usb_task();                                  //Inicia actividades USB
      printf(lcd_putc, "\f\n      ESPERANDO");     //Muestra en la LCD
      printf(lcd_putc, "\n       CONEXION");       //Muestra en la LCD
      usb_wait_for_enumeration();                  //Esperanda que el PIC sea reconocido por la PC (El driver debe estar instalado)
      printf(lcd_putc, "\f  DESARROLLADO POR");    //Muestra en la LCD
      printf(lcd_putc, "\n  CARLOS  GUERRERO");    //Muestra en la LCD
      lcd_gotoxy(5,4);                             //Posicion en la LCD (X, Y)
      printf(lcd_putc, "DESCONECTADO");            //Muestra en la LCD
   }
   UsarCDC = 1;
   UsarLCD = 0;
   output_high(LED_ROJO);
   output_low(LED_AZUL);
   while(true){
      //if((input(PIN_C0)==1)&&(input(PIN_C1)==1)){UsarLCD = 1; UsarCDC = 1;} 
         //else if((input(PIN_C0)==0)&&(input(PIN_C1)==1)){UsarLCD = 1; UsarCDC = 0;}
            //else if((input(PIN_C0)==1)&&(input(PIN_C1)==0)){UsarLCD = 0; UsarCDC = 1;}
      if(UsarCDC == 1){
         while(!usb_cdc_connected()){}                //Ciclo infinito mientras que no sea abierto el puerto COM con la PC
         usb_task();                               //Reinicia actividades USB
         if(usb_enumerated()){
            while(1){
               if(usb_cdc_kbhit()){
                  dato=usb_cdc_getc();
                  if (dato == 'D') reset_cpu();
                  else if (dato == 'C') break;
               }
            }
         }
      }
      reset_datos();
      while(datos_listos==0);
      procesar_resultados();
   }
}

