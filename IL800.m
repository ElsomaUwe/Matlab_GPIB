classdef IL800
    properties
        h % handle
    end
    methods
        function obj = IL800(handle)
            %Konstruktor
            obj.h = handle;
        end
        function send(obj, c)
            fprintf(obj.h,c);
        end
       function reset(obj)
            fprintf(obj.h,'*');
            disp("sent reset to IL800");
        end
        function init(obj)
            disp("Höcherl&Hackl elektronische Last\n")    
            fprintf(obj.h,'*RST');
            fprintf(obj.h,'*IDN?');
            idnString = fscanf(obj.h);
            disp(idnString);
         end
        function setCurrent(obj,current)
             s = sprintf("C%3.3f",current);
             s = strrep(s,' ','');
             disp(s);
            fprintf(obj.h,s);            
        end
        function setMode2(obj)
            fprintf(obj.h,'MODE2');
        end
        function on(obj)
            fprintf(obj.h,'ON');
        end
        function off(obj)
            fprintf(obj.h,'OFF');
        end
        function setRange0(obj)
           fprintf(obj.h,"BC0");          
       end

       function setRange1(obj)
           fprintf(obj.h,"BC1");          
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
