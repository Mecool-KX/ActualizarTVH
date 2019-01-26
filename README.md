# ActualizarTVH

## Actualización de los canales, Picons y EPG de TVHeadend para los Mecool en LibreELEC/CoreELEC

![alt text](https://raw.githubusercontent.com/Mecool-KX/ActualizarTVH/master/ActualizarTVH.png)

**EJECUCIÓN**

Iniciar sesión por ssh y ejecutar esta línea entera:

**wget -qO ./ActualizarTVH.sh https://goo.gl/z7MNyy ; chmod +x ./ActualizarTVH.sh ; ./ActualizarTVH.sh -UI ; rm ./ActualizarTVH.sh**



**INFORMACIÓN**

Si se lanza el script sin parámetros se ejecuta automáticamente la actualización de la guía.(Preparado para lanzarlo desde LE/CE)<br/>
**NOTA:** Se hace un backup de la carpeta de TVH y **se guardará la configuración realizada por el usuario**.

**-Parámetros disponibles-**<br/>

**-help:** Muestra información de ayuda<br/>
**-UI:** Aparece el menú para seleccionar la opcion que queramos. (Opción adecuada para lanzarlo desde SSH)<br/>
**-CHECK:** Comprueba si hay una versión más actual de NormandyEPG para instalar<br/>
**-CHECKINSTALL:** Comprueba si hay una versión más actual de NormandyEPG y la instala de forma automática<br/>

**NOTA:** Desde la última versión, si se hacen cambios en los canales de TVH, como añadir TDT o modificar algún canal, esos canales no serán machacados con la actualización.

Actualizaciones de los ficheros de TVH creados por **@DarzLir (Juan)**

https://normandy.es/
