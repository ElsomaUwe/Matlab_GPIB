classdef KA3000P <handle
    properties
        h
        comPort
        baudRate = 57600;  % Baudrate festlegen
    end
    methods
        function obj = KA3000P(handle)
            %obj.h = handle
        end
        function init(obj,comport)
            disp('KA3000P init');
            obj.comPort = comport;
            obj.h = serialport(obj.comPort, obj.baudRate);
            % Einstellungen anpassen (optional)
            obj.h.DataBits = 8;  % Datenbits
            obj.h.StopBits = 1;  % Stop-Bits
            obj.h.Parity = 'none';  % Parität
            obj.h.FlowControl = 'none';  % Flusskontrolle
        end
        function send(obj, c)
            obj.h.writeline(c);
        end
        function on(obj)
            obj.send("OUT1");
        end
        function off(obj)
            obj.send("OUT0");
        end
        function setVoltage(obj,voltage)
            
            s = sprintf("VSET1:%f",voltage);
            obj.send(s);
        end
    end
end