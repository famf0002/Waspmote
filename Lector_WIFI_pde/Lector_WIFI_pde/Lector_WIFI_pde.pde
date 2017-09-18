/*
    ------ Grabador Por WIFI --------
 AUTOR: Francisco Antonio Moya Fernández
 
 */

#include "WaspClasses.h"

//////////Configuración WIFI///////////////////
//librería WIFI
#include <WaspWIFI.h> //Librería módulo WIFI

//Configuración conexión WIFI
#define ESSID "MikroTik"
#define AUTHKEY "1234567890"

//Socket donde está conectado el módulo WIFI
uint8_t socket=SOCKET1;
///////////////////////////////////////////////

/////////////Configuración RFID////////////////
#include <WaspRFID13.h> //Librería módilo RFID
//--------------Constantes--------------

//Clave de autentificación del bloque de la tarjeta RFID que vamos a leer o escribir
//Esta clave es la de por defecto, aunque se puede cambiar
uint8_t keyAccess[] = {
  0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF};

//variable donde se almacenará el UID+Identificador
String UID;

//variable donde se almacenará el DNI
char dni[9];


///////////////////////////////////////////////

void setup()
{
  // Configuración conexión WIFI
  wifi_setup();

  // Inicio RFID
  rfid_setup();


}


void loop() {
    // put your main code here, to run repeatedly:
    wifi_setup();
    WIFI.OFF();

}

//Función conexión con AP WIFI
void wifi_setup()
{
  USB.println(F("======================================"));
  // Switch ON the WiFi module on the desired socket
  if( WIFI.ON(socket) == 1 )
  {
    USB.println(F("Wifi ON"));
  }
  else
  {
    USB.println(F("Wifi no se ha inicializado correctamente"));
  }

  // 1. Configure the transport protocol (UDP, TCP, FTP, HTTP...) 
  WIFI.setConnectionOptions(HTTP); 
  // 2. Configure the way the modules will resolve the IP address. 
  WIFI.setDHCPoptions(DHCP_ON);    

  // 3. Configure how to connect the AP 
  WIFI.setJoinMode(MANUAL); 
  // 4. Set Authentication key
  WIFI.setAuthKey(WPA1,AUTHKEY); 
  
  // 5. Store changes  
  WIFI.storeData();
  WIFI.getIP();
  //USB.println(WIFI.getIP());
  
  USB.println(F("======================================"));

}


//Función inicio módulo RFID
void rfid_setup(){
  USB.println(F("======================================"));
  //Inicia el módulo RFID
  RFID13.ON(SOCKET0);
  USB.println("Módulo RFID Iniciado");
  USB.println(F("======================================")); 
}

char * reciveDatosWifi(){
  char datos[32];
  if(WIFI.read(NOBLO)>0){
    //Recogemos datos del servidor
    for(int j=0; j<WIFI.length; j++){
      datos[j] = WIFI.answer[j];
      USB.print(datos[j]);
    }
  }
  return datos;
}

