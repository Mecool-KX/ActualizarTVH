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
NOMBRE_BACKUP="BACKUP_TVH.tar.gz"
CARPETA_BACKUP1="/storage/picons"
CARPETA_BACKUP2="/storage/.kodi/userdata/addon_data/service.tvheadend42"
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

#
# Chequeamos la versión que tenemos para ver si es diferente que la que hay en github
#
function ChequearActualizacion() {

	# Descargamos la última versión disponible a la carpeta temporal
	wget -q -O "/tmp/$ACTUALIZACION_VER" "$ACTUALIZACION_URL$ACTUALIZACION_VER"
	if [[ "$?" != 0 ]]; then
		MostrarError "Error en la descarga del fichero $ACTUALIZACION_VER \n\a Comprueba la conexión a Internet${NC}"		
	else
		# El fichero se ha descargado bien. Comprobamos que las versiones sean iguales
		ver_web=`cat /tmp/$ACTUALIZACION_VER 2>/dev/null`
		ver_local=`cat $CARPETA_DESCARGA/$ACTUALIZACION_VER 2>/dev/null`
		if [ "$ver_web" != "$ver_local" ]; then
			# Hay una diferencia de versiones. Descargamos la información de la versión web para mostrarla
			cambios=$(curl -s ${ACTUALIZACION_URL}changes_${ver_web}.txt)
			echo -e "\n${GREEN}¡¡¡Versión nueva encontrada ($ver_web)!!!!${NC}\n"
			MessageToKodi "Versión $ver_web disponible para descargar"
			echo "$cambios"
		else
			echo -e "No hay actualizaciones disponibles\n\n---Versión instalada: $ver_web---"
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
	clear

	if [ "$#" -eq 0 ]; then
		write_header "       Actualización de TVH y Picons"
		echo -e "\n\aSe va a proceder a la actualización\n"
		read -p $'¿Quieres continuar \033[0;31m(S|N)\033[0m?: ' opcion
		echo " "
	else
		opcion="S"
	fi
	case $opcion in
		s|S|Si|Si|si)
		
		# Creamos la carpeta de descarga de la actualización
		mkdir -p "$CARPETA_DESCARGA"
		cd "$CARPETA_DESCARGA"
		
		# Descargamos el fichero de configuración
		wget -q "$ACTUALIZACION_URL$ACTUALIZACION_TAR"
		if [[ "$?" != 0 ]]; then
			MostrarError "Error en la descarga del fichero $ACTUALIZACION_TAR \n\a Comprueba la conexión a Internet${NC}"		
		else
			# El fichero se ha descargado bien
			
			systemctl stop service.tvheadend42
			
			# Hacemos un backup de TVH
			if [ "$#" -eq 0 ]; then
				#Hacemos el backup preguntando
				HacerBackup
			else
				#Hacemos backup sin preguntar y machacando un posible anterior backup
				HacerBackup "NO_UI"
			fi
			
			# Borramos los datos de TVH
			BorramosDatosTVH
			
			# Restauramos el fichero descargado
			tar -xf "$CARPETA_DESCARGA/$ACTUALIZACION_TAR" -C /
			
			# Iniciamos el servicio TVH
			systemctl start service.tvheadend42			
			
			# Borramos el fichero descargado .tar
			rm -f "$CARPETA_DESCARGA/$ACTUALIZACION_TAR"	

			# Guardamos la versión que acabamos de descargar
			wget -q -O "$CARPETA_DESCARGA/$ACTUALIZACION_VER" "$ACTUALIZACION_URL$ACTUALIZACION_VER"
			ver_local=`cat $CARPETA_DESCARGA/$ACTUALIZACION_VER 2>/dev/null`
			
			clear			
			echo -e "${GREEN}\n\a Actualización $ver_local concluida correctamente${NC}";

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
	write_header "       Restaurar backup"

	if [ -f "$CARPETA_DESCARGA/$NOMBRE_BACKUP" ] ; then
		# Si existe el backup preguntamos si quiere restaurarlo
		while true
		do	
			echo -e "\n\a  Existe el backup en $CARPETA_DESCARGA/$NOMBRE_BACKUP\n"
			read -p "  ¿Deseas restaurarlo? (S|N): " opcion
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
		echo -e "${RED}\n\a  No existe el backup en $CARPETA_DESCARGA/$NOMBRE_BACKUP\n${NC}"
		pause
	fi

	if [ "$restaurar_backup" = true ]; then
		
			
		# Paramos el TVH
		systemctl stop service.tvheadend42

		clear
		echo -e "${GREEN}Restauramos el backup: $CARPETA_DESCARGA/$NOMBRE_BACKUP${NC}";

		# Borramos los datos de TVH
		BorramosDatosTVH

		cd "$CARPETA_DESCARGA"

		# Restauramos el backup guardado
		tar -xzf ""$NOMBRE_BACKUP"" -C /

		# Iniciamos el servicio TVH
		systemctl start service.tvheadend42

	fi

}

#
# Hacer un backup de TVH
#
function GuardarBackup(){

	HacerBackup

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

		rm -rf /storage/picons

		cd /storage/.kodi/userdata/addon_data/service.tvheadend42/

		rm -f config
		rm -f settings.xml

		rm -rf bouquet/
		rm -rf channel/
		rm -rf epggrab/
		rm -rf input/
		rm -rf service_mapper/
		rm -rf xmltv/

}

# Mandar un mensaje a Kodi
function MessageToKodi() {

	if [ "$#" -eq 0 ]; then # Si nos pasan un según parámetro son los milisegundos que quieren 
		kodi-send -a "Notification($NOMBRE_APP,$1, 5000)" >/dev/null
	else
		kodi-send -a "Notification($NOMBRE_APP,$1,$2)" >/dev/null
	fi
}

#
# Hacemos el backup
#
function HacerBackup(){
	local opcion
	local hacer_backup=true

	clear
	write_header "       Hacer backup"

	if [ "$#" -eq 0 ]; then #Hacemos la pregunta antes de machacar el anterior backup
		if [ -f "$CARPETA_DESCARGA/$NOMBRE_BACKUP" ] ; then
		# Si existe el backup preguntamos si quiere borrarlo
			while true
			do	
				echo -e "\n\a  Existe un backup ya generado en $CARPETA_DESCARGA/$NOMBRE_BACKUP\n"
				read -p "  ¿Deseas generar uno nuevo? (S|N): " opcion
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
		
		clear
		echo -e "${GREEN}Creamos el backup: $CARPETA_DESCARGA/$NOMBRE_BACKUP${NC}";
		cd "$CARPETA_DESCARGA"
		rm -f "$NOMBRE_BACKUP"

		# Hacemos un backup comprimido a fichero
		tar -czf "$NOMBRE_BACKUP" "$CARPETA_BACKUP1" "$CARPETA_BACKUP2" 

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
	echo " 3.  Restaurar BACKUP TVHeadend"
	echo " 4.  Guardar BACKUP TVHeadend"
	echo " 5.  Reiniciar servicio TVHeadend"
	echo " 6.  Salir"
	echo " "
}
#
# Purpose - Get input via the keyboard and make a decision using case..esac 
#
function Read_input() {
	local opcion
	read -p $'Selecciona una opcion \033[0;31m[1 - 6]\033[0m ' opcion
	case $opcion in
		1) ActualizarGuia;;
		2) ChequearActualizacion;pause;;
		3) RestaurarBackup;;
		4) GuardarBackup;;
		5) ReiniciarTVH;;
		6) echo "Adios!"; clear; exit 0;;
		*) echo "$opc no es una opcion válida.";
		   pause;;	
	esac
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
	echo -e "\e[32m${GREEN}-----------------------------------------------------\e[0m"
	echo -e "\e[32m${GREEN}${h}\e[0m"
	echo -e "\e[32m${GREEN}-----------------------------------------------------\e[0m"
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
	clear
	write_header "********  Actualización TVH de NormandyEPG  *********"
	echo -e "\n\a  ${RED} $1${NC}" 1>&2
	pause 
	exit 1
}
#
# Mostrar ayuda
#
function MostrarAyuda() {

	clear
	
	echo  -e "\nUso: ActualizarTVH [-CHECK] [-UI]\n"
	echo  "Actualización de los canales, Picons y EPG de TVHeadend para los Mecool en LibreELEC/CoreELEC\n"
	echo  "Uso:"
	echo  "	(Sin parámetros)   Actualización automática"
	echo  "	-CHECK             Comprueba si hay actualización disponible"
	echo  "	-UI                Menú interactivo de instalación"
	echo  " -help              Muestra esta informción"

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

clear
write_header "********  Actualización TVH de NormandyEPG  *********"

if [ $HOSTNAME != "LibreELEC" ] &&  [ $HOSTNAME != "CoreELEC" ];then
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
			break;;
		-CHECK) # Chequeamos a ver si hay actualización disponible
			ChequearActualizacion;
			break;;
		-UI) # Mostramos el menú

			while true
			do
				clear
				Show_menu  # accede al menú 
				Read_input # espera la respuesta del usuario
			done
			break;;
		*) # Error en el parámetro introducido
			MostrarAyuda;
			break;;
	esac

else

	if [ $# -eq 0 ]; then
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



