close all;
% Define the sweeps
thrSweep = 400; % Tether Lengths to Sweep Through
altSweep = 100:50:300; % Altitudes to sweep through
flwSweep = 0.4:0.1:1; % Flow Speed to simulate

% Initialize arrays to store data
flowSpeeds = [];
altitudes = [];
avgElecPowers = [];

% Loop through each combination of flow speed and altitude
for flwSpd = flwSweep
    for altitude = altSweep
        % Construct the filename
        filename = sprintf('PathFollow_V-%.2f_Alt-%d_thr-%d.mat', flwSpd, altitude, thrSweep);
        
        % Load the .mat file
        if isfile(filename)
            data = load(filename);
            

            % Calculate the lap-average electrical power
            avgElecPow = mean(data.tsc.elecPow);
            
            % Store the data
            flowSpeeds = [flowSpeeds, flwSpd];
            altitudes = [altitudes, altitude];
            avgElecPowers = [avgElecPowers, avgElecPow];
        end
    end
end

% Create the 3D plot
figure;
scatter3(flowSpeeds, altitudes, avgElecPowers, 'filled');
xlabel('Flow Speed (m/s)');
ylabel('Altitude (m)');
zlabel('Lap-Average Electrical Power (W)');
title('Lap-Average Electrical Power vs Flow Speed and Altitude');
grid on;

saveas(gcf, 'powersurface.png')