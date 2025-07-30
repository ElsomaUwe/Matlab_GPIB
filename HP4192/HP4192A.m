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
            s = sprintf("%s init",obj.name);
            disp(s);
        end
        
        function reset(obj)
            disp("HP4192A does not support *RES");
            % fprintf(obj.h,'*RST');
        end

        function setTimeout(obj,t)
            obj.h.Timeout = t;
        end
            
        function [tf,statusByte] = getStatus(obj)
            [tf,statusByte] = visastatus(obj.h);
        end

        function trigger(obj)
            obj.h.visatrigger();
        end

        function send(obj, c)
            writeline(obj.h,c);
        end
        
        function rxMsg = read(obj)
            rxMsg = readline(obj.h);
        end
        
        function setFormat2(obj)
            obj.send("F0");
        end

        function setFormat3(obj)
            obj.send("F1");
        end

        function trigger_EX(obj)
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

        function recall(obj,nr)
            s = sprintf("RC%1d",nr);
            obj.send(s);
        end

        function setSpotFreq(obj,f)
            s = sprintf('FR%09.4fEN',f/1000);
            obj.send(s);
        end

        function setOscLevel(obj,lvl)
            s = sprintf('OL%09.4fEN',lvl);
            obj.send(s);
        end
        function setSpotBias(obj,bias)
            s = sprintf('BI%09.4fEN',bias);
            obj.send(s);
        end
        function setBiasOff(obj)
            s = sprintf("I0EN");
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
        
        function [number,letters] = extractData(obj,inputStr)
            % Definieren des regulären Ausdrucks
            pattern = '([A-Z]{1,4})([-+]?\d+(\.\d+)?([eE][-+]?\d+)?)';
    
            % Extrahieren der Informationen mit dem regulären Ausdruck
            matches = regexp(inputStr, pattern, 'tokens','once');
    
            % Überprüfen, ob ein gültiges Ergebnis vorliegt
            if ~isempty(matches)
                letters = matches{1};
                number = str2double(matches{2});
            else
                error('Keine Übereinstimmung gefunden!');
            end
        end

        
        function [valuecell] = readAll_B(obj)
            s = strings(3,1);
            result = cell(2,3);
            obj.setFormat3();
            rxMsg = obj.read();
            resVektor = char(strtrim(strsplit(rxMsg,',')));
            [elements ~] = size(resVektor);
            for i=1:elements
                %display(i,:) = (resVektor(i,:));
                s(i) = string(resVektor(i,:)).strip;
                [result{1,i},result{2,i}]=obj.extractData(s(i));
            end
            valuecell = result;
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
        

    end
end
