classdef R6144
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        h
    end
    
    methods
        function obj = R6144(handle)
            %Konstruktor
            obj.h = handle;
        end
        function send(obj, c)
            fprintf(obj.h,c);
        end
        function init(obj)
            disp("R6144 init\n")   
            %obj.send("C1");
            %fprintf(obj.h,'C');
            %fprintf(obj.h,'*IDN?');
        end
        function setVoltage(obj,voltage)
            s = sprintf("D%3fV",voltage);
            disp(s);
            fprintf(obj.h,s);            
        end
        function on(obj)
            s = sprintf("E1");
            disp(s);
            fprintf(obj.h,s);            
        end
        function off(obj)
            s = sprintf("H1");
            disp(s);
            fprintf(obj.h,s);            
        end
       
        
    end
end

