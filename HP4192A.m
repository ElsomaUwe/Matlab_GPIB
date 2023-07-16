classdef HP4192A
    properties
        h
        name = 'HP4192A';
     end
    methods
        function obj = HP4192A(handle)
            %Konstruktor
            disp("HP4192A Konstruktor");
            obj.h = handle;
        end
        function init(obj)
            
        end
        
        function reset(obj)
            disp("HP4192A does not support *RES");
            % fprintf(obj.h,'*RST');
        end
        
        function send(obj, c)
            fprintf(obj.h,c);
        end
        
        function rxMsg = read(obj)
            rxMsg = fscanf(obj.h);
        end
        
        function setFormat2(obj)
            obj.send("F0");
        end

        function setFormat3(obj)
            obj.send("F1");
        end

        function trigger(obj)
            obj.send("EX");
        end
        
        function setTrigInt(obj)
            obj.send("T1");
        end
        
        function setTrigExt(obj)
            obj.send("T2");
        end
        
        function setTrigHold(obj)
            obj.send("T3");
        end
        
        function setCircuitmodeAuto(obj)
            obj.send("C1");
        end
         
        function setCircuitmodeSeries(obj)
            obj.send("C2");
        end
        
        function setCircuitmodeParallel(obj)
            obj.send("C3");
        end
         
        function setModeZdeg(obj)
            obj.send("A1B1T2F1");
        end
        
        function setModeZrad(obj)
            obj.send("A1B2T2F1");
        end
        
        function setModeR(obj)
            obj.send("A2T2F1");
        end
 
        function setModeLQ(obj)
            obj.send("A3B1T2F1");
        end
        
        function setModeLD(obj)
            obj.send("A3B2T2F1");
        end
        
        function setModeLR(obj)
            obj.send("A3B3T2F1");
        end
        
        function setModeCQ(obj)
            obj.send("A4B1T2F1");
        end
        
        function setModeCD(obj)
            obj.send("A4B2T2F1");
        end
        
        function setModeCR(obj)
            obj.send("A4B3T2F1");
        end

        function setRCL(obj,nr)
            s = sprintf("RC%1d",nr);
            obj.send(s);
        end

        function setSpotFreq(obj,f)
            s = sprintf("FR+%fEN",f);
            obj.send(s);
        end
        function [values qualifier] = readAll(obj)
            s = strings(3,1);
            obj.setFormat3();
            rxMsg = obj.read();
            resVektor = char(strtrim(strsplit(rxMsg,',')));
            [elements ~] = size(resVektor);
            for i=1:elements
                %display(i,:) = (resVektor(i,:));
                s(i) = string(resVektor(i,:)).strip;
            end
            ValueA = str2double(extractAfter(s(1),4));
            QualifierA = extractBefore(s(1),5);
            ValueB = str2double(extractAfter(s(2),4));
            QualifierB = extractBefore(s(2),5);
            ValueC = str2double(extractAfter(s(3),1));
            QualifierC = extractBefore(s(1),2);
            values = [ValueA ValueB ValueC];
            qualifier = [QualifierA QualifierB QualifierC];
        end
        
        function [value,Unit,status] = getDisplayA(obj)
            data = obj.read();
            
        end
        
        function srq = checkSRQ(obj)
            obj.send('*STB?');
           % x = obj.read();
            x = str2num(fscanf(obj.h));
            srq = bitget(x, 4);
        end
        function close(obj,slot,ch)
            s = sprintf("ROUTe:CLOSe (@%1d%02d)",slot,ch);
            fprintf(obj.h,s);
        end
        function list = closeQ(obj)
            s = sprintf("ROUTe:CLOSE?");
            fprintf(obj.h,s);            
            list = fscanf(obj.h);
        end
        function openAll(obj)
            s = sprintf("ROUTe:OPEN:ALL");
            fprintf(obj.h,s);            
        end
        

    end
end
