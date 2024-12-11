function varargout = Grafica(varargin)
% GRAFICA MATLAB code for Grafica.fig
%      GRAFICA, by itself, creates a new GRAFICA or raises the existing
%      singleton*.
%
%      H = GRAFICA returns the handle to a new GRAFICA or the handle to
%      the existing singleton*.
%
%      GRAFICA('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in GRAFICA.M with the given input arguments.
%
%      GRAFICA('Property','Value',...) creates a new GRAFICA or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Grafica_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Grafica_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Grafica

% Last Modified by GUIDE v2.5 29-Apr-2019 16:01:41

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Grafica_OpeningFcn, ...
                   'gui_OutputFcn',  @Grafica_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% --- Executes just before Grafica is made visible.
function Grafica_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to Grafica (see VARARGIN)

% Choose default command line output for Grafica
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% --- Outputs from this function are returned to the command line.
function varargout = Grafica_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

function pb1_Callback(hObject, eventdata, handles)  %Funcion para abrir el puerto
%Ingreso y verificacion del puerto
clc;                                            %Limpia la ventana de comandos
com=get(handles.npuerto,'String');              %Toma el valor digitado del edit text
if isempty(com)||isnan(str2double(com))         %Verifica si el valor ingresado es un numero
    errordlg('No has ingresado un numero.');    %Si no es un numero arroja un mensaje de error
    return                                      %Regresa al inicio de la funcion para que se ingrese otro valor
end                                             %Si es un numero sale directamente y sigue a la linea siguiente

%Configuracin del puerto serial
delete(instrfind({'port'},{['COM', com]}));     %Verifica el estado del puerto COM, si esta abierto, lo cierra
puerto = serial(['COM',com]);                   %Guardará todas las configuraciones del puerto en la variable "puerto"
set(puerto,'BaudRate',19200);                   %Se configura la velocidad a 19200 Baudios
set(puerto,'DataBits',8);                       %Se configura que el dato es de 8 bits
set(puerto,'Parity','none');                    %Se configura sin paridad
set(puerto,'StopBits',1);                       %Se configura bit de parada a uno
set(puerto,'FlowControl','none');               %Se configura sin control de flujo
set(puerto,'Timeout',5);                        %5 segundos de tiempo de espera
puerto.InputBufferSize=2000;                    %”n” es el número de bytes a recibir
puerto.Terminator='LF';                         %Caracter con que finaliza la recepcion de datos, en PIC CCS es "/n"
try                                             %Verifica si existe o no el puerto
    fopen(puerto);                              %Abre el puerto COM
    %fprintf(puerto,'%s','E');                       %Envia por CDC el caracter "E" (revisar codigo de PIC CCS)
    set(handles.pb1,'Visible', 'off');              %Oculta el boton "CONECTAR"
    set(handles.pb2,'Visible', 'on');               %Muestra el boton "DESCONECTAR"
    set(handles.pb3,'Visible', 'on');               %Muestra el boton "GRAFICAR"
    set(handles.cb1,'Visible', 'on');               %Muestra el CheckBox para autorrango de Iac Pico
    set(handles.cb2,'Visible', 'on');               %Muestra el CheckBox para autorrango de Vac Pico   
    set(handles.lcd,'Visible', 'on');               %Muestra el CheckBox para usar la LCD en el modulo del PIC
    set(handles.lcd,'Value', [0]);                  %El valor inicial para la LCD es "DESACTIVADA"
    set(handles.estado,'String', 'Conectado', 'ForegroundColor', [0 1 0]);  %Cambia el texto y color del static text del estado de la conexion
    set(handles.text1,'String', ' ');               %Limpia el static text de Vac RMS
    set(handles.text2,'String', ' ');               %Limpia el static text de Iac RMS
    set(handles.text30,'String', ' ');              %Limpia el static text de Preal
    set(handles.text32,'String', ' ');              %Limpia el static text del tiempo transcurrido para graficar 1 periodo    
    set(handles.text34,'String', ' ');              %Limpia el static text de Prms
    set(handles.text35,'String', ' ');              %Limpia el static text del Factor de Potencia
    set(handles.text37,'String', ' ');              %Limpia el static text del Potencia Reactiva
    set(handles.text41,'String', ' ');              %Limpia el static text de Potencia Consumida en Khw    
    set(handles.text43,'String', ' ');              %Limpia el static text del tiempo que ha transcurrido mientras consume potencia
    handles.CONECTADO=puerto;                       %Guarda todas las configuraciones de "puerto" en una variable no volatil
    guidata(hObject,handles);
catch                                           %Si da error al abrir ejecuta la linea siguiente
    errordlg(['Puerto COM ',com,' no existe, verifique en el administrador de dispositivos']);    %Hubo un error, arroja un mensaje de error
end                                             %Si no hubo error al abrir el puerto, sigue con la ejecucion del codigo


function pb2_Callback(hObject, eventdata, handles)  %Funcion para desconectar o cerrar el puerto COM
puerto=handles.CONECTADO;                       %Toma la configuracion del puerto de la variable "CONECTADO" 
fprintf(puerto,'%s','D');                       %Envia por CDC el caracter "D" (revisar codigo de PIC CCS)
fclose(puerto);                                 %Cierra el puerto COM
delete(puerto)                                  %Borra la variable "puerto"
axes(handles.graf1);                            %Selecciono la grafica de Vac Pico
cla;                                            %Limpio la grafica antes seleccionada
axes(handles.graf2);                            %Selecciono la grafica de Iac Pico
cla;                                            %Limpio la grafica antes seleccionada
set(handles.pb1,'Visible', 'on');               %Muestra el boton "CONECTAR" 
set(handles.pb2,'Visible', 'off');              %Oculta el boton "DESCONECTAR"
set(handles.pb3,'Visible', 'off');              %Oculta el boton "GRAFICAR"
set(handles.cb1,'Visible', 'off');              %Oculta el CheckBox para autorrango de Iac Pico  
set(handles.cb2,'Visible', 'off');              %Oculta el CheckBox para autorrango de Vac Pico
set(handles.lcd,'Visible', 'off');              %Oculta el CheckBox para usar la LCD en el modulo del PIC
set(handles.text1,'String', ' ');               %Limpia el static text de Vac RMS
set(handles.text2,'String', ' ');               %Limpia el static text de Iac RMS
set(handles.text30,'String', ' ');              %Limpia el static text de Preal
set(handles.text32,'String', ' ');              %Limpia el static text del tiempo transcurrido para graficar 1 periodo    
set(handles.text34,'String', ' ');              %Limpia el static text de Prms
set(handles.text35,'String', ' ');              %Limpia el static text del Factor de Potencia
set(handles.text37,'String', ' ');              %Limpia el static text del Potencia Reactiva
set(handles.text41,'String', ' ');              %Limpia el static text de Potencia Consumida en Khw
set(handles.text43,'String', ' ');              %Limpia el static text del tiempo que ha transcurrido mientras consume potencia
set(handles.estado,'String', 'Desconectado', 'ForegroundColor', [1 0 0]);   %Cambia el texto y color del static text del estado de la conexion
clear all                                       %Limpia todas las variables
%clc;                                            %Limpia la ventana de comandos

function pb3_Callback(hObject, eventdata, handles)  %Funcion que grafica los periodos
puerto=handles.CONECTADO;
handles.estado=1;                       
set(handles.text1,'String', ' ');               %Limpia el static text de Vac RMS
set(handles.text2,'String', ' ');               %Limpia el static text de Iac RMS
set(handles.text30,'String', ' ');              %Limpia el static text de Preal
set(handles.text32,'String', ' ');              %Limpia el static text del tiempo transcurrido para graficar 1 periodo    
set(handles.text34,'String', ' ');              %Limpia el static text de Prms
set(handles.text35,'String', ' ');              %Limpia el static text del Factor de Potencia
set(handles.text37,'String', ' ');              %Limpia el static text del Potencia Reactiva
set(handles.text41,'String', ' ');              %Limpia el static text de Potencia Consumida en Khw
set(handles.text43,'String', ' ');              %Limpia el static text del tiempo que ha transcurrido mientras consume potencia
Kwh = 0;
Tiempo = 0;
clc;
data1 = zeros(1, 128);
data2 = zeros(1, 128);
temp1 = zeros(1, 512);
temp2 = zeros(1, 512);
ciclo = 0;
while handles.estado                       %Guarda todas las configuraciones de "puerto" en una variable no volatil
    tic;                                            %Inicia el cronometro
    muestras = 128;                                 %Indica que son 128 muestras por periodo
    fprintf(puerto,'%s','C');                       %Envia por CDC el caracter "E" (revisar codigo de PIC CCS)
    data_txt=fscanf(puerto);                        %Almacena los valor que envia el PIC por CDC
    data=strread(data_txt,'%06d');                  %Convierte los valores de "data_txt" en un vector con valores internos en ASCII tamaño 5
    for n=1:muestras                                %Inicia separacion de las muestras
        %El PIC envia intercalados los valores de Vac e Iac Pico
        data1(n)=data(2*n-1);                       %Envia de forma impar los de Vac Pico
        data2(n)=data(2*n);                         %En forma par los de Iac Pico
    end                                             %Finaliza separacion de datos
    data2 = data2*(-1)
    %Inicia proceso de cuantificacion y graficacion
     %Inicia con la grafica de Vac Pico
        axes(handles.graf1);                            %Selecciona la grafica de Vac Pico
        plot(data1/10, 'x-b');                             %Grafica los valores cuantificados de Vac Pico, puntea cada valor del vector con una "x" de color azul
        value_cb2 = get(handles.cb2, 'Value');          %Lee el estado del check box de autorango
        if value_cb2 == 1;                              %Verifica si se usa o no el auto rango
            set(handles.graf1, 'SortMethod', 'depth', 'xgrid', 'on', 'ygrid', 'on', 'Xlim', [1 128], 'YlimMode', 'Auto');  %Si está activo, el rango del eje Y es automatico
        else                                            %Sino
            set(handles.graf1, 'SortMethod', 'depth', 'xgrid', 'on', 'ygrid', 'on', 'Xlim', [1 128], 'Ylim', [-200 200], 'YTick', [-200; -150; -100; -50; 0; 50; 100; 150; 200]);  %Si está desactivado, el rango del eje Y es fijo
        end                                             %Finaliza la graficacion de Vac Pico    
        
      %Inicia con la grafica de Iac Pico
        axes(handles.graf2);                            %Selecciona la grafica de Iac Pico
        plot(data2/1000, '*-g');                             %Grafica los valores cuantificados de Vic Pico, puntea cada valor del vector con una "*" de color verde
        value_cb1 = get(handles.cb1, 'Value');          %Lee el estado del check box de autorango
        if value_cb1 == 1;                              %Verifica si se usa o no el auto rango
            set(handles.graf2, 'SortMethod', 'depth', 'xgrid', 'on', 'ygrid', 'on', 'Xlim', [1 128], 'YlimMode', 'Auto');  %Si esta activo, el limete Y es automatico
        else                                            %Sino
            set(handles.graf2, 'SortMethod', 'depth', 'xgrid', 'on', 'ygrid', 'on', 'Xlim', [1 128], 'Ylim', [-40 40], 'YTick', [-40; -35; -30; -25; -20; -15; -10; -5; 0; 5; 10; 15; 20; 25; 30; 35; 40]); %Si está desactivado, el rango del eje Y es fijo
        end                                             %Finaliza la graficacion de Iac Pico  

	%Cuantificacion de Vac RMS
    
    Preal=0;  Irms=0; Vrms=0;
    for k = 1:muestras
      vv = data1(k)/10.00;
      ii = data2(k)/1000.00;
      Irms  = Irms + (ii*ii);
      Vrms  = Vrms + (vv*vv);
      Preal = Preal + (ii*vv);
    end
    Irms=sqrt(Irms/muestras);
    Preal=Preal/muestras; 
    Vrms=sqrt(Vrms/muestras);
    Prms = Vrms*Irms;  
    factor = Preal/Prms;
    if Vrms<0.5
       Vrms=0.0;
    end
    if Irms<0.2
       Irms=0.0; Prms=0.0; Preal=0.0; factor=0.0;
    end
     if factor>0.99
        Preal=Prms; factor=1.0;
     end
    set(handles.text1, 'String', Vrms);                         %Muestra el valor de Vrms en el static text correspondiente
    set(handles.text2, 'String', Irms);                         %Muestra el valor de Irms en el static text correspondiente
    set(handles.text30, 'String', Preal);                       %Muestra el valor de la Potencia Real Consumida (W) en el static text correspondiente
    set(handles.text34, 'String', Prms);                        %Muestra el valor de la potencia Aparente (VA) en el static text correspondiente    
    set(handles.text35, 'String', factor);                      %Muestra el valor del Factor de Potencia en el static text correspondiente
    set(handles.text37, 'String', Prms-Preal);                  %Muestra el valor de la Potencia Reactiva (VAR) en el static text correspondiente
    set(handles.text44, 'String', 0.00);                      %Muestra el valor del Factor de Potencia en el static text correspondiente
    set(handles.text46, 'String', 0.00);                  %Muestra el valor de la Potencia Reactiva (VAR) en el static text correspondiente
    drawnow;                                                     %Dibuja las graficas (SI SE DESEARA GRAFICAR VARIOS PERIODOS, SIN ESTE CODIGO SOLO GRAFICARIA EL ULTIMO)   
    if Preal > 0
        Kwh = Kwh+(Preal*toc/3600000);
        Tiempo = Tiempo+(toc/60);
    end
    set(handles.text41, 'String', Kwh);                  %Muestra el valor de la Potencia Reactiva (VAR) en el static text correspondiente
    set(handles.text43, 'String', Tiempo);
    set(handles.text32, 'String',toc*1000);                    %Muestra el tiempo desde el inicio del cronometro hasta este punto, se miltiplica x mil para pasar de segundos a milisegundos
    %xlswrite('Grafica.xlsx',data1,'Hoja',ff,ff,'A1');
    %xlswrite('Grafica.xlsx',data2,'Hoja2','A1');
    n=1;
    for k=(ciclo*128)+1:muestras*(ciclo+1)
        temp1(k)=data1(n);
        temp2(k)=data2(n);
        n=n+1;
    end
    ciclo = ciclo + 1;
    if ciclo == 4
        ciclo = 0;
        %disp(fprintf('%d,',temp1));
        %disp(fprintf('%d,',temp2));
    end
end                                                             %Si graficó todos los periodos salta a la siguiente linea, si no regresa al inio del ciclo "for"

% --- Executes on button press in cb1.
function cb1_Callback(hObject, eventdata, handles)
% hObject    handle to cb1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --- Executes on button press in cb2.
function cb2_Callback(hObject, eventdata, handles)
% hObject    handle to cb2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

function npuerto_Callback(hObject, eventdata, handles)
% hObject    handle to npuerto (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --- Executes during object creation, after setting all properties.
function npuerto_CreateFcn(hObject, eventdata, handles)
% hObject    handle to npuerto (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)   %Cierra el puerto en el caso que se cierre la ventana sin antes no dar clic en el boton "DESCONECTAR"

try                             %Intenta realizar las siguientes funciones, si no hay ningun error en estas lineas salta directamente a "end"
    puerto=handles.CONECTADO;   %Toma la configuracion del puerto de la variable "CONECTADO" 
    fprintf(puerto,'%s','D');   %Envia por CDC el caracter "D" (revisar codigo de PIC CCS)
    fclose(puerto);             %Cierra el puerto COM
    delete(puerto)              %Borra la variable "puerto"
    %clc;                        %Limpia la ventana de comandos
    delete(hObject);            %Cierra la figura
    clear all                   %Limpia todas las variables
catch                           %Si hubo algun error al ejecutar las lineas anteriores, salta a la linea siguiente
    delete(hObject);            %Cierra la figura
    clear all                   %Limpia todas las variables
    %clc;                        %Limpia la ventana de comandos
end

% --- Executes on button press in lcd.
function lcd_Callback(hObject, eventdata, handles)  %Da la orden al PIC de usar o no la LCD
puerto=handles.CONECTADO;                           %Toma la configuracion del puerto de la variable "CONECTADO" 
value_lcd = get(handles.lcd, 'Value');              %Lee el estado del check box de la LCD
        if value_lcd == 1;                          %Si es 1
            fprintf(puerto,'%s','L');               %Envia por CDC el caracter "L" (revisar codigo de PIC CCS)
        else                                        %Sino
            fprintf(puerto,'%s','N');               %Envia por CDC el caracter "N" (revisar codigo de PIC CCS)
        end


% --- Executes when figure1 is resized.
function figure1_SizeChangedFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in pb7.
function pb7_Callback(hObject, eventdata, handles)
% hObject    handle to pb7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function graf1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to graf1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: place code in OpeningFcn to populate graf1
