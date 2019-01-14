#!/bin/bash

################### NormandyEPG #####################
# 		Actualización de la EPG de TVH y Picons
##################################################### 

# Definición de variables
NOMBRE_APP="NormandyEPG"
ACTUALIZACION_URL="https://raw.githubusercontent.com/NormandyEPG/TvH-ListaMovistar/master/"
ACTUALIZACION_TAR="NormandyEPG.tar"
ACTUALIZACION_VER="NormandyEPG.ver"
CARPETA_DESCARGA="/storage/.kodi/NormandyEPG"
CARPETA_TEMPORAL="$CARPETA_DESCARGA/tmp"
NOMBRE_BACKUP="BACKUP_TVH.tar"
CARPETA_TVH="/storage/.kodi/userdata/addon_data/service.tvheadend42"
CARPETA_PICONS="$CARPETA_DESCARGA/picons"
LOG_FILE="/var/log/ActualizarTVH.log"
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

#
# Chequeamos la versión que tenemos para ver si es diferente que la que hay en github
#
function ChequearActualizacion() {
	actualizacion="false"
	
	rm -f "/tmp/$ACTUALIZACION_VER"
	clear
	# Descargamos la última versión disponible a la carpeta temporal
	wget ${ncert} -q -O "/tmp/$ACTUALIZACION_VER" "$ACTUALIZACION_URL$ACTUALIZACION_VER"
	if [ $? -ne 0 ]; then
		MostrarError "Error en la descarga del fichero $ACTUALIZACION_VER${NC}"		
	else

		# El fichero se ha descargado bien. Comprobamos que las versiones sean iguales
		ver_web=`cat /tmp/$ACTUALIZACION_VER 2>/dev/null`
		ver_local=`cat $CARPETA_DESCARGA/$ACTUALIZACION_VER 2>/dev/null`
		cambios=$(curl -s ${ACTUALIZACION_URL}Changes_${ver_web}.txt)
#echo "ver_web: $ver_web - ver_local: $ver_local - cambios: $cambios";pause

		
		if [ "$ver_web" != "$ver_local" ]; then
			actualizacion="true"
			# Hay una diferencia de versiones. Descargamos la información de la versión web para mostrarla
			MostrarMensaje "\n¡¡¡¡¡¡¡¡Versión nueva encontrada ($ver_web)!!!!!!!!!\n" "GREEN"
			MostrarMensaje "\n$cambios" "GREEN"
		else
			MostrarMensaje "No hay actualizaciones disponibles\n\n---Versión instalada: $ver_web---" "RED"
			MostrarMensaje "\n$cambios" 
		fi

	fi
}

#
# Actualizacion
#
function ActualizarGuia(){
local opcion
#
while true
do
	if [ "$#" -eq 0 ]; then
		clear
		echo -e "\n\a Se va a proceder a la actualización de TVHeadend\n"
		read -p $'¿Quieres continuar \033[0;31m(S|N)\033[0m?: ' opcion
	else
		opcion="S"
		MostrarMensaje "Actualizamos la guía de modo silencioso" "WHITE"
	fi
	case $opcion in
		s|S|Si|Si|si)
		
		# Creamos la carpeta de descarga de la actualización
		mkdir -p "$CARPETA_DESCARGA"
		mkdir -p "$CARPETA_TEMPORAL"
		cd "$CARPETA_DESCARGA"
		
		# Descargamos el fichero de configuración
		MostrarMensaje "Descargamos el fichero de actualización: $ACTUALIZACION_TAR" "WHITE"
		wget ${ncert} -q "$ACTUALIZACION_URL$ACTUALIZACION_TAR" 2>&1 | tee $LOG_FILE
		if [ $? -ne 0 ]; then
			MostrarError "Error en la descarga del fichero $ACTUALIZACION_URL$ACTUALIZACION_TAR \n\a Comprueba la conexión a Internet"	
		else
			# El fichero se ha descargado bien
			MostrarMensaje "Fichero $ACTUALIZACION_TAR descargado correctamente" "WHITE"
			
			systemctl stop service.tvheadend42
			
			# Hacemos un backup de TVH
			if [ "$#" -eq 0 ]; then
				#Hacemos el backup preguntando
				HacerBackup
			else
				#Hacemos backup sin preguntar y machacando un posible anterior backup
				HacerBackup "NO_UI"
			fi
			
			#Borramos datos de TVH
			MostrarMensaje "Borramos los datos de TVH"
			if [ "$#" -eq 0 ]; then
				BorramosDatosTVH
			else
				# Borramos los datos de TVH
				BorramosDatosTVH "NO_UI"
			fi
			
			# Restauramos el fichero descargado
			MostrarMensaje "Restauramos el fichero $CARPETA_DESCARGA/$ACTUALIZACION_TAR"
			tar -xf "$CARPETA_DESCARGA/$ACTUALIZACION_TAR" -C $CARPETA_TEMPORAL
			
			# Hacemos un rsync para no sobreescribir los ficheros que ya existan
			MostrarMensaje "Copiamos de la carpeta $CARPETA_TEMPORAL"
			cd $CARPETA_TEMPORAL
			false | cp -ai * / 2>/dev/null # Copiamos los ficheros que no existan
			
			# Iniciamos el servicio TVH
			systemctl start service.tvheadend42			
			
			# Borramos el fichero descargado .tar
			MostrarMensaje "Hacemos limpieza"
			rm -f "$CARPETA_DESCARGA/$ACTUALIZACION_TAR"
			rm -rf "$CARPETA_TEMPORAL"

			# Guardamos la versión que acabamos de descargar
			wget ${ncert} -q -O "$CARPETA_DESCARGA/$ACTUALIZACION_VER" "$ACTUALIZACION_URL$ACTUALIZACION_VER"
			ver_local=`cat $CARPETA_DESCARGA/$ACTUALIZACION_VER 2>/dev/null`
			MostrarMensaje "Actualizamos el fichero $ACTUALIZACION_VER: $ver_local"
			
			MostrarMensaje "Actualización $ver_local concluida correctamente" "GREEN"

			MessageToKodi "Actualizacion $ver_local concluida correctamente"
			
		fi
		break;;
		n|N|No|NO|no) break;;
		*) echo "$opcion no es una opcion válida.";
		   pause;;
	esac
done
}


#
# Restaurar el backup de TVH generado
#
function RestaurarBackup(){
	local opcion
	local restaurar_backup=false

	clear

	if [ -f "$CARPETA_DESCARGA/$NOMBRE_BACKUP" ] ; then
		# Si existe el backup preguntamos si quiere restaurarlo
		while true
		do	
			echo -e "\n\a  Existe el backup en $CARPETA_DESCARGA/$NOMBRE_BACKUP\n"
			read -p $'  ¿Deseas restaurarlo? \033[0;31m(S-N)\033[0m: ' opcion
			
			case $opcion in
				n|N) break;;
				s|S) restaurar_backup=true;
					 break;;
				*) echo "$opcion no es una opcion válida.";
			   pause;;
			esac
		done
	else
		# No tiene existe un fichero para restaurar
		MostrarMensaje "\n\a  No existe el backup en $CARPETA_DESCARGA/$NOMBRE_BACKUP\n" "RED"
		pause
	fi

	if [ "$restaurar_backup" = true ]; then
		
		MostrarMensaje "Restauramos el backup: $CARPETA_DESCARGA/$NOMBRE_BACKUP"
	
		# Paramos el TVH
		systemctl stop service.tvheadend42

		# Borramos los datos de TVH
		BorramosDatosTVH "ALL"

		cd "$CARPETA_DESCARGA"

		# Restauramos el backup guardado en la carpeta temporal (el parámetro k no funciona)
		tar -xf "$NOMBRE_BACKUP" -C /

		# Iniciamos el servicio TVH
		systemctl start service.tvheadend42

	fi

}

#
# Hacemos el backup
#
function HacerBackup(){
	local opcion
	local hacer_backup=true

	if [ "$#" -eq 0 ]; then 
		clear
		#Hacemos la pregunta antes de machacar el anterior backup
		if [ -f "$CARPETA_DESCARGA/$NOMBRE_BACKUP" ] ; then
		# Si existe el backup preguntamos si quiere borrarlo
			while true
			do	
				echo -e "\n\a  Existe un backup ya generado en $CARPETA_DESCARGA/$NOMBRE_BACKUP\n"
				read -p $'¿Deseas generar uno nuevo? \033[0;31m(S|N)\033[0m: ' opcion
				case $opcion in
					s|S) break;;
					n|N) hacer_backup=false;
						break;;
				*) echo "$opcion no es una opcion válida.";
				pause;;
				esac
			done
		fi
	fi
	
	if [ "$hacer_backup" = true ]; then
		
		MostrarMensaje "Creamos el backup: $CARPETA_DESCARGA/$NOMBRE_BACKUP"
		cd "$CARPETA_DESCARGA"
		rm -f "$NOMBRE_BACKUP"

		# Hacemos un backup comprimido a fichero
		tar -cf "$NOMBRE_BACKUP" "$CARPETA_TVH" "$CARPETA_PICONS"
		MostrarMensaje "Terminado de crear el backup"
	fi
}

# Mirar si hay versión nueva, y si es así, instalarla
function ChequearInstalar() {

	ChequearActualizacion
	
	if [ $actualizacion = "true" ]; then
	
		# Lanzamos la actualización automática
		ActualizarGuia "NO_UI"
	fi
	if [ "$#" -eq 1 ]; then pause;fi
}

#
# Reiniciamos el servicio de TVH
#
function ReiniciarTVH(){

	systemctl restart service.tvheadend42

}

#
# Borramos los datos antes de la restauración
#
function BorramosDatosTVH(){

carpeta_channel="$CARPETA_TVH/channel/config/*"
carpeta_tag="$CARPETA_TVH/channel/tag/*"
	local opcion
	local borrar_todo=false

	if [ "$#" -eq 0 ]; then 
		clear
		# Preguntamos si quiere borrar toda la información previa
		while true
		do	
			echo -e "\n\a  Si contestamos que NO a la siguiente pregunta guardaremos nuestra configuración particular de canales y grupos\n"
			read -p $'¿Deseas borrar TODA la información previa de canales y grupos? \033[0;31m(S|N)\033[0m: ' opcion
			case $opcion in
				s|S) borrar_todo=true;break;;
				n|N) break;;
			*) echo "$opcion no es una opcion válida.";
			pause;;
			esac
		done

	else
		if [ "$1" = "ALL" ];then
			borrar_todo=true
		fi
	fi
	
	rm -rf "$CARPETA_PICONS"

	cd $CARPETA_TVH

	rm -f config
	rm -f settings.xml

	rm -rf bouquet/
#		rm -rf channel/
#		rm -rf input/
	rm -rf epggrab/
	rm -rf input/dvb/networks/b59c72f4642de11bd4cda3c62fe080a8/
	rm -rf input/dvb/networks/0cd94ffd696f612cddc28324babf5159/
	rm -rf service_mapper/
	rm -rf xmltv/

	if [ "$borrar_todo" = false ]; then
		# Recorremos los ficheros de estas carpetas para borrar solo los que tengan la marca
		for fichero in $carpeta_channel $carpeta_tag
		do 
		   if [ -f "$fichero" ]; then  
			 ultima=$(tail -n 1 $fichero)
			 if [[ "$ultima" = $NOMBRE_APP ]]; then
			   rm -f $fichero 
			 fi
		   fi
		done
	else
		# Borramos todos los canales y tags
		rm -rf $carpeta_channel
		rm -rf $carpeta_tag
	fi

}

# Mandar un mensaje a Kodi
function MessageToKodi() {

	if [ "$#" -eq 1 ]; then # Si nos pasan un segundo parámetro son los milisegundos que quieren 
		kodi-send -a "Notification($NOMBRE_APP,$1, 5000)" >/dev/null
		
	else
		kodi-send -a "Notification($NOMBRE_APP,$1,$2)" >/dev/null
	fi
}

#
# Muestra el menú principal
#
function Show_menu()
{
	clear
	write_header "********  Actualización TVH de NormandyEPG  *********"
	echo -e "\n"
	echo " 1.  Actualización ONLINE de TVHeadend"
	echo " 2.  Comprobar si hay versión nueva disponible"
	echo " 3.  Comprobar si hay versión nueva e instalarla"
	echo " 4.  Restaurar BACKUP TVHeadend"
	echo " 5.  Guardar BACKUP TVHeadend"
	echo " 6.  Reiniciar servicio TVHeadend"
	echo ""
	echo " 0.  Salir"
	echo " "
}
#
# Purpose - Get input via the keyboard and make a decision using case..esac 
#
function Read_input() {
	local opcion
	read -p $'Selecciona una opcion \033[0;31m[0 - 6]\033[0m ' opcion
	case $opcion in
		1) ActualizarGuia;;
		2) ChequearActualizacion;pause;;
		3) ChequearInstalar "PAUSE";;
		4) RestaurarBackup;;
		5) HacerBackup;;
		6) ReiniciarTVH;;
		0) exit 0;;
		*) echo "$opc no es una opcion válida.";
		   pause;;	
	esac
	clear
}
#
# Función pause
#
function pause(){
	local message="$@"
	echo "$@"
#	sleep 1
	[ -z $message ] && message="presiona [Enter] para continuar..."
	read -p "$message" readEnterKey
}
#
# Purpose - Display header message
# $1 - message
#
function write_header(){
	local h="$@"
	local TIMESTAMP=`date "+%Y-%m-%d %H:%M:%S"`
	echo -e "\e[32m${GREEN}-----------------------------------------------------\e[0m"
	echo -e "\e[32m${GREEN}${h}\e[0m"
	echo -e "\e[32m${GREEN}-----------------------------------------------------\e[0m"
	echo "$TIMESTAMP $h" >> $LOG_FILE
}

#
# Comprobamos si hay Internet
#
function CompruebaInternet() {

wget -q --spider http://google.com

if [ $? -ne 0 ]; then
	MostrarError "Es necesario disponer de conexión a Internet{NC}"
fi

}

#
# Mostrar error
#
function MostrarError() {
	local TIMESTAMP=`date "+%Y-%m-%d %H:%M:%S"`
	clear
	echo -e "\n\a  ${RED} $1${NC}" 1>&2
	echo "$TIMESTAMP $1" >> $LOG_FILE
	pause 
	exit 1
}

#
# Mostrar mensaje
#
function MostrarMensaje() {		
	local TIMESTAMP=`date "+%Y-%m-%d %H:%M:%S"`

	case "$2" in
		GREEN) # Verde
			echo -e "${GREEN}$1${NC}"
			;;
		RED) # Rojo
			echo -e "${RED}$1${NC}";
			;;
		*) # Sin color
			echo -e "$1";
			;;
	esac

	echo "$TIMESTAMP $1" >> $LOG_FILE
}


#
# Mostrar ayuda
#
function MostrarAyuda() {
	
	echo  -e "\nUso: ActualizarTVH [-CHECK] [-UI] [-help]"
	echo  "Actualización de los canales, Picons y EPG de TVHeadend para los Mecool en LibreELEC/CoreELEC"
	echo  "Uso:"
	echo  "	(Sin parámetros)   Instalación automática (no borra configuraciones particulares)"
	echo  "	-CHECK             Comprueba si hay actualización disponible"
	echo  "	-CHECKINSTALL      Comprueba si hay actualización disponible, y si la hay, la instala"
	echo  "	-UI                Menú interactivo de instalación"
	echo  "	-help              Muestra esta informción"

}

#
# Cuenta atrás
#
function CuentaAtras() {

	echo "Pulsa Ctrl+C para abortar"
	secs=$2
	while [ $secs -gt 0 ]; do
	   echo -ne "$1 en ${RED}$secs${NC} segundos\033[0K\r"
	   sleep 1
	   : $((secs--))
	done		

}

#
# Principal
#
#!/bin/bash

# Borramos el fichero de log y el de la actualización si existieran
rm -f "$LOG_FILE"
rm -f "$CARPETA_DESCARGA/$ACTUALIZACION_TAR"

# Comprobamos si tenemos instalado el wget-ssl
[ -f /storage/.opt/bin/wget ] && ncert="--no-check-certificate"

clear
write_header "********  Actualización TVH de NormandyEPG  *********"

SO=`lsb_release | cut -d' ' -f1`
if [ "$SO" != "LibreELEC" ] &&  [ "$SO" != "CoreELEC" ];then
	MostrarError "Este script solo se puede ejecutar en LibreELEC o CoreELEC" 
fi

# Comprobamos si tenemos internet
CompruebaInternet
 
# Si no pasan parámetros, mostramos el menú
if [[ $# -eq 1 ]]; then
	# Nos han pasado un parámetro. Comprobamos que sea uno de los permitidos
	case $1 in
		-help) # Mostramos la información del programa
			MostrarAyuda;
			;;
		-CHECK) # Chequeamos a ver si hay actualización disponible
			ChequearActualizacion;;
			
		-CHECKINSTALL) # Chequeamos si hay nueva versión, y si la hay la instalamos de modo automático
		
			ChequearInstalar;;
		-UI) # Mostramos el menú

			while true
			do
				Show_menu  # accede al menú 
				Read_input # espera la respuesta del usuario
			done
			;;
		*) # Error en el parámetro introducido
			MostrarAyuda;
			;;
	esac

else

	if [ $# -eq 0 ]; then
	
		MessageToKodi "Iniciamos instalacion de NormandyEPG"
		# Lanzamos la actualización automática desatendida
		CuentaAtras "Se va a lanzar la actualización automática" 10
		
		# Lanzamos la actualización automática
		ActualizarGuia "NO_UI"
	else
		# Más de un parámetro
		 MostrarAyuda
	fi
fi

#
exit 0



