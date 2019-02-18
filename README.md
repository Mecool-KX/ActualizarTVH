# ActualizarTVH

## Actualización de los canales, Picons y EPG de TVHeadend para los Mecool en CoreELEC

![alt text](https://raw.githubusercontent.com/Mecool-KX/ActualizarTVH/master/ActualizarTVH.png)

**EJECUCIÓN**

Iniciar sesión por ssh y ejecutar esta línea entera:

**wget -qO ./ActualizarTVH.sh https://goo.gl/z7MNyy ; chmod +x ./ActualizarTVH.sh ; ./ActualizarTVH.sh ; rm ./ActualizarTVH.sh**


**-Parámetros disponibles-**<br/>

**-help:** Muestra información de ayuda<br/>
**-ACTUALIZA:** Actualización desatendida. Preparado para lanzarlo desde CoreELEC<br/>
**-CHECK:** Comprueba si hay una versión más actual de NormandyEPG para instalar<br/>
**-CHECKINSTALL:** Comprueba si hay una versión más actual de NormandyEPG y la instala de forma automática<br/>

**NOTAS:** 

- Si se hacen cambios en los canales de TVH, como añadir TDT o modificar algún canal, esos canales no serán machacados con la actualización.

- Desde la última versión, mediante el interfaz de usuario, se da la opción de borrar toda la configuración para hacer una instalación limpia, o de actualizar solo los cambios

- Si al ejecutar la línea no aparece ningún mensaje, es posible que se deba a que tenemos instalada la versión wget de Entware. Para que funcione, podemos desinstalar Entware o añadir el parámetro **--no-check-certificate** antes de **-qO**

Actualizaciones de los ficheros de TVH creados por **@DarzLir (Juan)**

https://normandy.es/
