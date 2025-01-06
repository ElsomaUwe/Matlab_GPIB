classdef IL800
    properties
        h % handle
        comPort
        baudRate = 19200;  % Baudrate festlegen
    end
    methods
        function obj = IL800(address)
            %Konstruktor
            disp('IL800 init');
            if ischar(address) || isstring(address)
                % Falls address ein String ist, wird davon ausgegangen, dass es sich um einen COM-Port handelt.
                obj.comPort = address;
                obj.h = serialport(address, obj.baudRate);
                % Einstellungen anpassen (optional)
                obj.h.DataBits = 8;  % Datenbits
                obj.h.StopBits = 1;  % Stop-Bits
                obj.h.Parity = 'none';  % Parität
                obj.h.FlowControl = 'none';  % Flusskontrolle           
            elseif isa(address,'gpib')
                % Falls address eine Zahl ist, wird davon ausgegangen, dass es sich um eine GPIB-Adresse handelt.
                obj.h = address; % Beispiel für die Initialisierung eines GPIB-Handles
            else
                error('Ungültiger Eingabedatentyp. Erwartet wird ein String für den COM-Port oder ein GPIB handler');
            end
        end
        function send(obj, c)
            if(isa(obj.h,'internal.Serialport'))
                writeline(obj.h,c);
            elseif(isa(obj.h,'gpib'))
                fprintf(obj.h,c);
            else
                error('Handle Typ ist weder COM noch gpib');
            end
        end

        function msg = read(obj)
            if(isa(obj.h,'serialport'))
                msg = readline(obj.h);
            elseif(isa(obj.h,'gpib'))
                msg = fscanf(obj.h);
            else
                error('Handle Typ ist weder COM noch gpib');
            end
        end
        
       function reset(obj)
            obj.send("*");
            disp("sent reset to IL800");
        end
        function init(obj)
            disp("Höcherl&Hackl elektronische Last\n")    
            obj.send("*");
            obj.setMode2();
            obj.setRange0();
         end
        function setCurrent(obj,current)
             s = sprintf("C%3.3f",current);
             s = strrep(s,' ','');
             disp(s);
             obj.send(s);
        end
        function setMode2(obj)
            obj.send('MODE2');
        end
        function on(obj)
            obj.send("ON");
        end
        function off(obj)
            obj.send("OFF");
        end
        function setRange0(obj)
           obj.send("BC0");          
       end

       function setRange1(obj)
           obj.send("BC1");          
       end
       function setRange2(obj)
           fprintf(obj.h,"BC2");          
       end
       function setRange3(obj)
           fprintf(obj.h,"BC3");          
       end
     function rsMsg = getCurrent(obj)
            fprintf(obj.h,"INC");
            rxMsg = fscanf(obj.h);
            disp(rxMsg);
       end
     function rsMsg = getVoltage(obj)
            fprintf(obj.h,"INV");
            rxMsg = fscanf(obj.h);
            disp(rxMsg);
       end
     function rsMsg = getPower(obj)
            fprintf(obj.h,"INP");
            rxMsg = fscanf(obj.h);
            disp(rxMsg);
       end
 
    end
end
