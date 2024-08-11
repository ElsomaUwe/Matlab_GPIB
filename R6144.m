classdef R6144
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        h       %gpib handle for this device
        name = "Advantest R6144 programmable DC Voltage/Current Generator";
        status = deviceStatus.offline;
    end
    
    methods
        function obj = R6144(handle)
            %Konstruktor
            obj.h = handle;
            obj.status = deviceStatus.online;
        end
        function init(obj)
            disp("R6144 init\n")   
         end
        function reset(obj)
            %fprintf(obj.h,'*RST');
        end
        function send(obj, c)
            fprintf(obj.h,c);
        end
        function rxMsg = getIDN(obj)
            %this device has no SCPI
            rxMsg = obj.name;
        end
        function setOnOff(obj,value)
            if (value == 0)
                s = sprintf("H1");
            else
                s = sprintf("E1");
            end
            obj.send(s);
        end
 
        function on(obj)
            s = sprintf("E1");
             obj.send(s);
       end
        function off(obj)
            s = sprintf("H1");
             obj.send(s);
       end       
        function setVoltage(obj,voltage)
            s = sprintf("D%3fV",voltage);
            obj.send(s);
        end
       
        
    end
end

