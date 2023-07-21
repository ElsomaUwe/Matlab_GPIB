function [value, unit] = str2value(str)
    % Float-Zahl mit optionaler Einheit extrahieren
    match = regexp(str, '(-?\d+\.?\d*(?:e-?\d+)?)\s*(\w*)', 'tokens', 'once');

    if ~isempty(match)
        floatNum = str2double(match{1});
        unit = match{2};
    
        % fprintf('Extrahierte Float-Zahl: %.2e\n', floatNum);
        % fprintf('Extrahierte Einheit: %s\n', unit);
    else
        disp('Keine Float-Zahl gefunden.');
    end
    value = floatNum;
end