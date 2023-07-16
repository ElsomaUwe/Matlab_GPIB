classdef T962 <handle
    properties
        h
        name = 'T962';
        comPort = 'COM13'
        baudRate = 115200;  % Baudrate festlegen
    end
    methods
        function obj = T962()
            
        end
        function init(obj,comport)
            disp('T962 init');
            obj.comPort = comport;
            obj.h = serialport(obj.comPort, obj.baudRate);
            % Einstellungen anpassen (optional)
            obj.h.DataBits = 8;  % Datenbits
            obj.h.StopBits = 1;  % Stop-Bits
            obj.h.Parity = 'none';  % Parität
            obj.h.FlowControl = 'none';  % Flusskontrolle
        end
        function send(obj, c)
            obj.h.write(c);
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