%
% Use these variables to enable/disable different parts of the script.
%
loadImages           = true;  % also displays silhouettes
displayVolumeCorners = true;
computeVisualHull    = true;
displayVolumeSlices  = false;
displayIsoSurface    = true;

%
% Adjust these variables, one at a time, to get a good visual hull.
%

% Task 9.1 silhouette threshold
% This should be a suitable value between 0 and 255
silhouetteThreshold = 100; 

% Task 9.2 define bounding box
% It should be as small as possible, but still contain the whole region of
% interest.
bbox = [0.2 -0.2 -1.8;2.7 1.6 2.5];
%bbox = [0 0 0; 3 3 3]; % [minX minY minZ; maxX maxY maxZ];
volumeX = 64;
volumeY = 64;
volumeZ = 128;
volumeThreshold = 17;

home;
numCameras = 18;
count = 1;
if loadImages
    % Load silhouette images and projection matrices
    for n=1:numCameras
        % Projection matrices
        % This does not normalize the depth value
        Ps{n} = textread(sprintf('../data/david_%02d.pa',n-1));
        Ps{n} = [eye(3,2) [1 1 1]']*Ps{n};  % add 1 for one-based indices
        % Images
        ims{n} = imread(sprintf('../data/david_%02d.jpg',n-1));
        % Silhouettes
        sils{n} = rgb2gray(ims{n})>silhouetteThreshold;
        
        figure(1);
        subplot(1,2,1);
        imshow(sils{n});
        subplot(1,2,2);
        imshow(double(rgb2gray(ims{n}))/255.*sils{n});
        drawnow;
    end
end

% Define transformation from volume to world coordinates.
T = [eye(4,3) [bbox(1,:) 1]'] * ...
    diag([(bbox(2,1)-bbox(1,1))/volumeX ...
          (bbox(2,2)-bbox(1,2))/volumeY ...
          (bbox(2,3)-bbox(1,3))/volumeZ ...
          1]);
T = [1  0 0 0; ...
     0  0 1 0; ...  % flip y and z axes for better display in matlab figure (isosurface)
     0 -1 0 0; ...
     0  0 0 1] * T;
T = T*[eye(4,3) [-[1 1 1] 1]'];  % subtract 1 for one-based indices

if displayVolumeCorners
    % Draw projection of volume corners.
    for n=1:numCameras
        figure(count);
        hold off;
        imshow(ims{n});
        hold on;
        corners = [[      0       0       0 1]' ...
                   [      0       0 volumeZ 1]' ...
                   [      0 volumeY       0 1]' ...
                   [      0 volumeY volumeZ 1]' ...
                   [volumeX       0       0 1]' ...
                   [volumeX       0 volumeZ 1]' ...
                   [volumeX volumeY       0 1]' ...
                   [volumeX volumeY volumeZ 1]'];
        pcorners = Ps{n}*T*corners;
        pcorners = pcorners./repmat(pcorners(3,:),3,1);
        plot(pcorners(1,:),pcorners(2,:),'g*');
        drawnow;
        pause(0.1);
        count = count+1;
    end
end

if computeVisualHull
    % Define volume. This is used to store the number of observations for
    % each voxel.
    volume = zeros(volumeX,volumeY,volumeZ);
    
    
     % Visual hull computation    
    % Task 9.3 Visual hull computation
    %   - For each image add one to the voxel if projection is within
    %     silhouette region.
    %   - Be careful with the order of coordinates. The point is stored as
    %     (x,y,z), but matrix element access in Matlab is mat(row,col).
    
    for x=1:volumeX
        for y = 1:volumeY
            for z = 1:volumeZ
                for n=1:numCameras %for every camera
                    sils_i = sils{n};
                    Ps_i = Ps{n};
                    xy = Ps_i*T*[x,y,z,1]'; %homogeneous volume coordinates trasformed into world coordinates and projection
                    xy = xy./repmat(xy(3,:),3,1); %de homo image coords
                    b = round(xy(2));
                    a = round(xy(1));
                    if((a > 0) && (a <= size(sils_i,2)) && (b > 0) && (b <= size(sils_i,1)))
                        if (sils_i(b,a) == 1)
                            volume(x,y,z) = volume(x,y,z) + 1; %add score 1
                        end
                    end
                end
            end
        end
    end
end    

if displayVolumeSlices
    figure(3);
    hold off;
    for n=1:size(volume,3)
        imagesc(volume(:,:,n));
        drawnow;
        pause(0.1);
    end
end

if displayIsoSurface
    % display result
    figure(4);
    clf;
    grid on;
    xlabel('x');
    ylabel('y');
    zlabel('z');
    hold on;
    [xMesh yMesh zMesh] = meshgrid(1:volumeY,1:volumeX,1:volumeZ);
    pt = patch(isosurface(yMesh, xMesh, zMesh, volume, volumeThreshold));
    set(pt,'FaceColor','red','EdgeColor','none');
    axis equal;
    daspect([volumeX/(bbox(2,1)-bbox(1,1)) volumeY/(bbox(2,2)-bbox(1,2)) volumeZ/(bbox(2,3)-bbox(1,3))]);
    camlight(0,0);
    camlight(180,0);
    camlight(0,90);
    camlight(0,-90);
    lighting phong;
    view(30,30);
end


