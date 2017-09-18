/*
    ------ Waspmote Control de Presencia RFID (Lee datos tarjeta y envia por wifi) --------
 
 Autor: Francisco Antonio Moya Fernández
 */

//--------------Librerias---------------
#include <WaspRFID13.h>
#include <WaspWIFI.h>
#include "WaspClasses.h"

//--------------Constantes--------------

uint8_t state_init, state_auth, state_read_dni, state_read_uid, state_readURL, state_WIFI;

//Clave de Acceso
uint8_t keyAccess[] = {
  0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF
};

//buffer de datos uint8_t
blockData data;

//variable donde se almacenará el DNI
char mensaje[64], fechaHora[30], json[300];
//Variable donde se almacenará el UID de la tarjeta
UIdentifier uid;

//Almacena las respuestas
ATQ ans;


String UID, dni, BODY;

//------------Constantes WIFI--------------
// choose socket (SELECT USER'S SOCKET)
///////////////////////////////////////
uint8_t socket=SOCKET1;
///////////////////////////////////////

// WiFi AP settings (CHANGE TO USER'S AP)
/////////////////////////////////
char ESSID[] = "Aquaris";
char AUTHKEY[] = "1234567890";
/////////////////////////////////
// WEB server settings
/////////////////////////////////
char HOST[] = "192.168.43.187";
int PORT = 8000;
char URL[]  = "GET$/rest/";
/////////////////////////////////

void setup()
{

  if( WIFI.ON(socket) == 1 )
  {    
    USB.println(F("WiFi switched ON"));
  }
  else
  {
    USB.println(F("WiFi did not initialize correctly"));
  }

  // 1. Configure the transport protocol (UDP, TCP, FTP, HTTP...)
  WIFI.setConnectionOptions(HTTP|CLIENT_SERVER);
  // 2. Configure the way the modules will resolve the IP address.
  WIFI.setDHCPoptions(DHCP_ON);
  // 3. Configure how to connect the AP 
  WIFI.setJoinMode(MANUAL);   
  // 4. Set the AP authentication key
  WIFI.setAuthKey(WPA2, AUTHKEY); 
  // 5. Save Data to module's memory
  WIFI.storeData();


  USB.println(F("Set up done"));



}
void loop()
{



  //##################################################
  // Switch ON the WiFi module on the desired socket
  if( WIFI.ON(socket) == 1 )
  {    
    USB.println(F("WiFi switched ON"));
  }
  else
  {
    USB.println(F("WiFi did not initialize correctly"));
  }

  // If it is manual, call join giving the name of the AP     
  if( WIFI.join(ESSID) )
  { 
    USB.println(F("Joined"));
    //Inicia el módulo USB
    USB.println("===============================================================================");
    USB.ON();
    USB.println(F("RFID: LEER TARJETA Y ENVIAR WIFI"));

    //##################################################
    //Inicia el módulo RFID
    RFID13.ON(SOCKET0);
    USB.println(F("RFID/NFC @ 13.56 MHz module started"));

  }

  UID = "";
  dni = "";

  state_init = RFID13.init(uid, ans);
  state_auth = RFID13.authenticate(uid, 1, keyAccess);
  state_read_uid = RFID13.read(0, data);
  state_read_dni = RFID13.read(1, data);

  if ( state_init == 0 ) //inicializa la lectura
  {
    if ( state_auth == 0 ) //autentifica la tarjeta
    {
      if ( state_read_uid == 0 ) //Se lee el BLOQUE 0 de la tarjeta RFID para sacar el UID, CRC y Datos de fabricante
      {
        //Se convierte los datos identificativos de la tarjeta, se convierte en a int, se normaliza a 3 dígitos y se inserta en un string
        for (int i = 0; i < 16; i++) {
          if ((int)data[i] > 9 ) {
            if ((int)data[i] > 99 ) {
              UID = UID + ((int)data[i]);
            } 
            else {
              UID = UID + "0" + ((int)data[i]);
            }
          } 
          else {
            UID = UID + "00" + ((int)data[i]);
          }
        }

        //Imprimimos por pantalla los datos recogidos
        USB.println();
        USB.print("UID: ");
        USB.println((const char*)&UID[0]);

        if ( state_read_dni == 0 )//Se recoge los datos del DNI que están guardados en el BLOQUE 1 de la tarjeta RFID
        {
          //Se almacena el DNI en un STRING
          for (int i = 0; i < 16; i++) {
            dni = dni + ((char)data[i]);
          }

          //Imprimimos por pantalla los datos recogidos
          USB.print("DNI: ");
          USB.println((const char*)&dni[0]);

          //Se monta la cadena Json para la URL
          sprintf(json, "\{\"id_lector\":\"1\",\"uid\":\"%s\",\"dni\":\"%s\"\}", (const char*)&UID[0], (const char*)&dni[0]);

          //Imprimimos La cadena JSON sin parsear
          USB.print("Cadena sin parsear: ");
          USB.println((const char*)&json[0]);

          //Parseamos la cadena JSON para que no inserte carácteres no permitidos en una URL
          BODY = json;
          BODY.replace("%", "%25");
          BODY.replace("{", "%7B");
          BODY.replace("}", "%7D");
          BODY.replace("\"", "%22");
          BODY.replace(" ", "%20");
          BODY.replace(":", "%3A");
          BODY.replace("=", "%3D");
          BODY.replace("'", "%60");
          BODY.replace("?", "%3F");
          BODY.replace("@", "%40");
          BODY.replace("&", "%26");
          BODY.replace("\\", "%5C");
          BODY.replace("~", "%7E");
          BODY.replace("#", "%23");

          //Imprimimos La cadena JSON parseada
          USB.print("Cadena Parseada: ");
          USB.println((const char*)&BODY[0]);
          ///////////////////////////////////////////
          // Creamos la petición HTTP
          ///////////////////////////////////////////
          USB.println("Petición HTTP");
          USB.print(F("host:"));
          USB.println(HOST);
          USB.print(F("port:"));
          USB.println(PORT);
          USB.print(F("url:"));
          USB.println(URL);
          USB.print(F("body:"));
          USB.println((char*)&BODY[0]);

          state_readURL = WIFI.getURL(IP, HOST , PORT , URL, (char*)&BODY[0]);
          if ( state_readURL == 1)
          {
            USB.println(F("\nHTTP query OK."));
            USB.print(F("WIFI.answer:"));
            USB.println(WIFI.answer);
          }
          else
          {
            USB.println(F("\nHTTP query ERROR"));
            USB.print(F("WIFI.answer:"));
            USB.println(WIFI.answer);
          }

        }
        else
        {
          USB.println("Error en la lectura de DNI");
        }
      }
      else
      {
        USB.println("Error en la lectura de UID");
      }
    }
    else
    {
      USB.println("Error en la autentificacion");
    }
  }
  else
  {
    USB.println("Error al inicializar");
  }

}



