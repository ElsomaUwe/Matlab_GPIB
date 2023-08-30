classdef HP66309D
    properties
        h
        name = "HP66309D DC Source";
    end
    methods
        function obj = HP66309D(handle)
            %Konstruktor
            obj.h = handle;
        end
        function init(obj)
            
        end
        function reset(obj)
            fprintf(obj.h,'*RST');
        end
        function send(obj, c)
            fprintf(obj.h,c);
        end
        function rxMsg = getIDN(obj)
            fprintf(obj.h,"*IDN?");
            rxMsg = fscanf(obj.h);
        end

        
        
        function setValueOnly(obj)
            fprintf(obj.h, ':FORM:ELEM READ,UNIT,TST');
        end
        function setVDC(obj)
            fprintf(obj.h,":SENSe:FUNCtion 'VOLT:DC'");
        end
        function getVDC(obj)
            result = obj.h.read;
            str2value(result);
        end
        function setVAC(obj)
            fprintf(obj.h,":SENSe:FUNCtion 'VOLT:AC'");
        end
        function setIDC(obj)
            fprintf(obj.h,":SENSe:FUNCtion 'CURR:DC'");
        end
        function setIAC(obj)
            fprintf(obj.h,":SENSe:FUNCtion 'CURR:AC'");
        end
        function setRES(obj)
            fprintf(obj.h,":SENSe:FUNCtion 'RES'");
        end
        function set4RES(obj)
            fprintf(obj.h,":SENSe:FUNCtion 'FRES'");
        end
        function setTEMP(obj)
            fprintf(obj.h,":SENSe:FUNCtion 'TEMPerature'");
        end
        function setFREQ(obj)
            fprintf(obj.h,":SENSe:FUNCtion 'FREQuency'");
        end
        function setPER(obj)
            fprintf(obj.h,":SENSe:FUNCtion 'PERiod'");
        end
        function setCONT(obj)
            fprintf(obj.h,":SENSe:FUNCtion 'CONTinuity'");
        end
        function trigger(obj)
            fprintf(obj.h,":INIT:IMMediate");
        end
        function setTrigCont(obj,a)
            fprintf(obj.h,":INIT:CONT %d",a);
        end
        function setTempRefSim(obj,value)
            s= sprintf("SENS:TEMP:TC:RJUN:SIM %f",value);
            fprintf(obj.h,s);
        end
        function rxMsg = read(obj)
            fprintf(obj.h,"READ?");
            rxMsg = fscanf(obj.h);
        end
        function rxMsg = fetch(obj)
            fprintf(obj.h,"FETCH?");
            rxMsg = fscanf(obj.h);
        end

        function srq = checkSRQ(obj)
            obj.send('*STB?');
           % x = obj.read();
            x = str2num(fscanf(obj.h));
            srq = bitget(x, 4);
        end        

    end
end
