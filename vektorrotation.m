% Definition des Vektors
vector = [1; 0; 0]; % Beispielvektor, kann angepasst werden

% Definition der Rotationsachse
axis = [0; 1; 0]; % Beispielachse, kann angepasst werden

% Anzahl der Animationsschritte
numSteps = 100;

% Winkelbereich der Rotation
thetaRange = linspace(0, 2*pi, numSteps);

% Initialisierung des Animationsfensters
figure;
hold on;
xlabel('X-Achse');
ylabel('Y-Achse');
zlabel('Z-Achse');
    
% Animationsschleife
for i = 1:numSteps
    % Berechnung des Rotationswinkels für den aktuellen Schritt
    theta = thetaRange(i);
    
    % Berechnung der Rotationsmatrix
    rotationMatrix = expm(crossProductMatrix(axis/norm(axis))*theta);
    
    % Rotation des Vektors
    rotatedVector = rotationMatrix * vector;
    
    % Darstellung des Vektors als Pfeil
    quiver3(0, 0, 0, rotatedVector(1), rotatedVector(2), rotatedVector(3), 'LineWidth', 2);
    
    % Aktualisierung des Animationsfensters
    drawnow;
    pause(0.05);
    
    % Entfernen des vorherigen Vektors
    if i < numSteps
        clf;
    end
end

% Funktion zur Erzeugung der Kreuzproduktmatrix
function crossMatrix = crossProductMatrix(v)
    crossMatrix = [0 -v(3) v(2);
                   v(3) 0 -v(1);
                  -v(2) v(1) 0];
end
