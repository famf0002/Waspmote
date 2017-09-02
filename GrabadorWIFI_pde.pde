/*
    ------ Grabador Por WIFI --------
 AUTOR: Francisco Antonio Moya Fernández
 
 */

// Put your libraries here (#include ...)
#include "WaspClasses.h"

//////////Configuración WIFI///////////////////
//librería WIFI
#include <WaspWIFI.h>

//Configuración conexión WIFI
#define ESSID "MikroTik"
#define AUTHKEY "1234567890"

//Socket donde está conectado el módulo WIFI
uint8_t socket=SOCKET1;
///////////////////////////////////////////////

/////////////Conexión TCP/IP///////////////////
#define IP_ADDRESS "192.168.0.65"
#define REMOTE_PORT 1111
#define LOCAL_PORT 2000

//timeout para la escucha de mensajes
#define TIMEOUT 10000

//variable para medir el tiempo
unsigned long previous;

///////////////////////////////////////////////

String recividos,estado;


void setup()
{
  // configuración de WIFI
  wifi_setup();

}


void loop()
{
  //Inicio del módulo WIFI
  WIFI.ON(socket);
  char datos[33];


  //Conexión con la red WIFI
  if (WIFI.join(ESSID)){
    
    USB.println(F("Conectado con el AP"));

    //Conexión con el socket TCP/IP
    if (WIFI.setTCPclient(IP_ADDRESS, REMOTE_PORT, LOCAL_PORT)){
      USB.println(F("Conexión TCP/IP establecida"));

      //Envio mensaje de inicio
      WIFI.send("{\"estado\":\"OK\"}");

      USB.println(F("A la espera de datos:"));
      previous=millis();

      while(millis()-previous<TIMEOUT){

        //recibo los datos a guardar en la tarjeta
        if(WIFI.read(NOBLO)>0){
          //Recogemos datos del servidor
          for(int j=0; j<33; j++){
            datos[j] = WIFI.answer[j];
          }
        }

        recividos = datos;

        USB.println((const char*)&recividos[0]);
        //Se recorta el valor de acción
        estado = recividos.substring(recividos.indexOf("{\"accion\":\"")+11,recividos.indexOf("\",\"dni\":\""));
        USB.println((const char*)&estado[0]);
        USB.println(estado.toInt());
        
        //Según la acción recogida se realiza las siguietes opciones
        switch (estado.toInt()){
        case 1: // Crear un nueva tarjeta
          //Se tiene que leer el UID y grabar los datos en la tarjeta
          
          //Envía los datos del UID y los datos guardados
          WIFI.send(datos);
          
          //Recivo si los datos que se han guardado están OK
          if(WIFI.read(NOBLO)>0){
            //Recogemos datos del servidor
            for(int j=0; j<33; j++){
              datos[j] = WIFI.answer[j];
            }
          }
          
          recividos = datos;
          //Se recorta el valor del estado
          estado = recividos.substring(recividos.indexOf("{\"estado\":\"")+11,recividos.indexOf("\"}"));
          USB.println((const char*)&estado[0]);
          WIFI.close();
          break;
        case 2:
          WIFI.close();
          break;
        case 3:
          WIFI.close();
          break;
        default:
          WIFI.close();
          break;

        }

        // Condición para evitar un desbordamiento
        if (millis() < previous)
        {
          previous = millis();	
        }



      }
      //USB.println(F("Impreso desde String"));
      //USB.println(datos);

      WIFI.send("{\"estado\":\"ok\"}");
      //WIFI.close();


    }
    else{
      USB.println(F("No se ha podido establecer la conexión TCP/IP")); 
    }

  }
  else {
    USB.println(F("No se ha podido conectar con el AP")); 
  }

}

//Función conexión con AP WIFI
void wifi_setup()
{
  // Switch ON the WiFi module on the desired socket
  if( WIFI.ON(socket) == 1 )
  {
    USB.println(F("Wifi switched ON"));
  }
  else
  {
    USB.println(F("Wifi did not initialize correctly"));
  }

  // 1. Configure the transport protocol (UDP, TCP, FTP, HTTP...) 
  WIFI.setConnectionOptions(CLIENT); 
  // 2. Configure the way the modules will resolve the IP address. 
  WIFI.setDHCPoptions(DHCP_ON);    

  // 3. Configure how to connect the AP 
  WIFI.setJoinMode(MANUAL); 
  // 4. Set Authentication key
  WIFI.setAuthKey(WPA1,AUTHKEY); 

  // 5. Store changes  
  WIFI.storeData();

}







