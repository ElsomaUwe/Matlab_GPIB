classdef gpibClass
    properties 
        name = 'NI GPIB USB-HS';
        index = 0;
        open = false;
    end
    %----
    methods
        % constructor
        function obj = gpibClass(varargin)
            if nargin == 0
                % disp('0');
            elseif nargin <= 2
                for i = 1:nargin
                    if isnumeric(varargin{i})
                        obj.index = varargin{i};
                    elseif ischar(varargin{i})
                        obj.name = varargin{i};
                    elseif isstring(varargin{i})
                        obj.name = char(varargin{i});
                    end
                end
            else
                disp('too much params');
            end
        end
        
        function init(obj)
            % reset interface
            instrreset;
            s = sprintf('%s: initialized',obj.name);
            disp(s);
        end
        
        function h = connect(obj,address)
            h = gpib('ni', obj.index, address);
            try fopen(h);
                s = sprintf('%s: opened GPIB device adress %d',obj.name,address);
                disp(s);
            catch exception
                h = 0;
                s = sprintf('%s: cannot open GPIB device adress %d',obj.name,address);
                disp(s);
                disp(exception);
            end
        end
        
        function close(obj,handle)
            s = 'xxx';
            try fclose(handle);
                s = sprintf('%s: closed handle');
                delete(handle);
                clear handle;
            catch exception
                s = sprintf('%s: cannot close handle');               
            end
            disp(s);
        end
    end
end