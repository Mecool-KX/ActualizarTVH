#!/bin/bash

################### NormandyEPG #####################
# 		Actualización de la EPG de TVH y Picons
##################################################### 

# Definición de variables
NOMBRE_APP="NormandyEPG"
ACTUALIZACION_URL="https://github.com/NormandyEPG/TvH-ListaMovistar/raw/master/"
ACTUALIZACION_TAR="NormandyEPG.tar"
CARPETA_DESCARGA="/storage/.kodi/NormandyEPG"
NOMBRE_BACKUP="BACKUP_TVH.tar.gz"
CARPETA_BACKUP1="/storage/picons"
CARPETA_BACKUP2="/storage/.kodi/userdata/addon_data/service.tvheadend42"
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

#
# Muestra el menú principal
#
function Show_menu()
{
	clear
	write_header "****************  Guía NormandyEPG  *****************"
	echo -e "\n"
	echo " 1.  Actualización ONLINE de la guía"	
	echo " 2.  Restaurar BACKUP TVHeadend"
	echo " 3.  Guardar BACKUP TVHeadend"
	echo " 4.  Reiniciar servicio TVHeadend"
	echo " 5.  Salir"
	echo " "
}
#
# Purpose - Get input via the keyboard and make a decision using case..esac 
#
function Read_input() {
	local opcion
	read -p $'Selecciona una opcion \033[0;31m[1 - 5]\033[0m ' opcion
	case $opcion in
		1) ActualizarGuia;;
		2) RestaurarBackup;;
		3) GuardarBackup;;
		4) ReiniciarTVH;;
		5) echo "Adios!"; clear; exit 0;;
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
# Actualizacion
#
function ActualizarGuia(){
local opcion
#
while true
do
	clear

	write_header "       Actualización de TVH y Picons"
	echo -e "\n\aSe va a proceder a la actualización\n"
	read -p $'¿Quieres continuar \033[0;31m(S|N)\033[0m?: ' opcion
	echo " "
	case $opcion in
		s|S|Si|Si|si)
		
		# Creamos la carpeta de descarga de la actualización
		mkdir -p "$CARPETA_DESCARGA"
		cd "$CARPETA_DESCARGA"

		rm -f "$ACTUALIZACION_TAR"
		
		# Descargamos el fichero de configuración
		wget -q "$ACTUALIZACION_URL$ACTUALIZACION_TAR"
		if [[ "$?" != 0 ]]; then
			echo -e "\n\a  ${RED}Error en la descarga del fichero $ACTUALIZACION_TAR \n\a Comprueba la conexión a Internet${NC}"
			pause			
		else
			# El fichero se ha descargado bien
			
			systemctl stop service.tvheadend42
			
			# Hacemos un backup de TVH
			HacerBackup
			
			# Borramos los datos de TVH
			BorramosDatosTVH
			
			# Restauramos el fichero descargado
			tar -xf "$CARPETA_DESCARGA/$ACTUALIZACION_TAR" -C /
			
			# Iniciamos el servicio TVH
			systemctl start service.tvheadend42			
			
			# Borramos el fichero descargado
			rm -f "$CARPETA_DESCARGA/$ACTUALIZACION_TAR"	

			clear			
			echo -e "${GREEN}\n\a Actualización concluida correctamente${NC}";
			sleep 3

			MessageToKodi "Actualizacion concluida correctamente"
			
		fi
		break;;
		n|N|No|NO|no) break;;
		*) echo "$opcion no es una opcion válida.";
		   pause;;
	esac
done
}


#
# Restaurar el backup generado
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
# Restaurar el backup generado
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

	kodi-send -a "Notification($NOMBRE_APP,$1)"
}

#
# Hacemos el backup
#
function HacerBackup(){
	local opcion
	local hacer_backup=true

	clear
	write_header "       Hacer backup"

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
# Principal
#
# ignore CTRL+C, CTRL+Z and quit singles using the trap
#trap '' SIGINT SIGQUIT SIGTSTP
#
#!/bin/bash
if [[ $EUID -ne 0 ]]; then
	clear
	write_header "       Actualizar EPG $NOMBRE_APP"
	echo -e "\n\a Este script debe ser ejecutado por el usuario root" 1>&2
	pause 
	exit 1
fi
#


# Si no pasan parámetros, mostramos el menú

while true
do
	clear
	Show_menu  # accede al menú 
	Read_input # espera la respuesta del usuario
done

#
exit 0



