function autoSplitter

numFolds = input('How many folders of data to analyse? ');
curDir = cd;
for n = 1:numFolds
    slctDir{n,:} = uigetdir(curDir,...
        sprintf('Please select location of the data files - %d',n));
    if isequal(slctDir,0)
        return
    end
    curDir = []; curDir = slctDir{n,:};
end

% add the java .jar fileparts
javaaddpath('C:\Program Files\MATLAB\R2016b\java\jar\ij.jar');
javaaddpath('C:\Program Files\MATLAB\R2016b\java\jar\mij.jar');

for n = 1:numFolds
    % get file information - names, file sizes, etc
    dataDir = dir(slctDir{n}); dataDir([1:2],:) = [];
    for n = 1:size(dataDir,1);
        tempName = [];
        tempName = dataDir(n).name;
        dataNames{n,:} = cellstr(tempName);
        spltNames{:,n} = split(tempName);
        tempSplt = spltNames{:,n};
        fileParts{n,:} = cellstr(tempSplt(end,:));
    end
    
    % create struct based on number of dishes
    for n = 1:size(spltNames,2)
        temp = spltNames{n};
        dishes(n,:) = temp(1,:);
    end
    uniqueDish = unique(dishes);
    
    
    % locate the filenames which consist of the unique dish
    for n = 1:size(uniqueDish,1);
        for m = 1:size(dataNames,1);
            k{n,m} = strfind(dataNames{m,:},uniqueDish(n,:));
            if cell2mat(k{n,m}) == 1
                dishSort{m,n} = dataNames{m,:};
            else
                continue
            end
        end
    end
    
    for n=1:size(dataNames,1);
        temp = dataNames{n}; temp = temp{1};
        k = strfind(temp,'green');
            if isempty(k) == 1
                k = NaN;
            end
        index(n,:) = k;
    end
    
    % launch MIJI
    MIJ.start
    
    % open files in MIJI
    for n = 1:size(dishSort,2)
        tempDish = [];
        for m = 1:size(dishSort,1)
            tempDish{m,1} = dishSort{m,n};
        end
        newTempDish = tempDish(~cellfun('isempty',tempDish));
        firstFile = newTempDish(end,:);
        otherFiles = newTempDish([1:end-1],:);
        newDishOrder = ([firstFile otherFiles]);
        newDishOrder = newDishOrder'
        for o = 1:size(newDishOrder,1)
            tempStr = []; dirFile = []; fileOpen = [];
            tempStr = newDishOrder{o}; tempStr = tempStr{1};
            dirFile = dataDir(1).folder; fileOpen = fullfile(dirFile,tempStr);
            MIJ.run('Open...',sprintf('path=[%s]',fileOpen))
        end
        % run file concatenation, based on file size
        c = size(newDishOrder,1);
        switch c
            case 2 % if there are two files
                dish1 = newDishOrder{1}; dish2 = newDishOrder{2};
                dish1 = dish1{1}; dish2 = dish2{1};
                MIJ.run('Concatenate...',...
                    sprintf('title=[Concatenated stacks] image1=[%s] image2=[%s] image3=[-- None --]',...
                    dish1,dish2));
            case 3 % if there are three files
                dish1 = newDishOrder{1}; dish2 = newDishOrder{2}; dish3 = newDishOrder{3};
                dish1 = dish1{1}; dish2 = dish2{1}; dish3 = dish3{1};
                MIJ.run('Concatenate...',...
                    sprintf('title=[Concatenated stacks] image1=[%s] image2=[%s] image3=[%s] image4=[-- None --]',...
                    dish1,dish2,dish3));
            case 4 % if there are four files
                dish1 = newDishOrder{1}; dish2 = newDishOrder{2}; dish3 = newDishOrder{3};...
                    dish4 = newDishOrder{4};
                dish1 = dish1{1}; dish2 = dish2{1}; dish3 = dish3{1}; dish4 = dish4{1};
                MIJ.run('Concatenate...',...
                    sprintf('title=[Concatenated stacks] image1=[%s] image2=[%s] image3=[%s] image4=[%s] image5=[-- None --]',...
                    dish1,dish2,dish3,dish4));
        end
        
        % get the sizing information for the files
        for n = 1:size(newDishOrder,1);
            temp = newDishOrder{n,:}; temp = temp{1};
            dirStruct = dir(fullfile(fileOpen,temp));
            fileSize(n,:) = dirStruct.bytes;
        end
        sumSize = sum(fileSize); gbSize = sumSize*10e-10;
        
        % split video based on concatenated video size
        if gbSize <= 1
            continue
        elseif 1 < gbSize <=2 % if file size is inbetween 1-2gb, split into half
            MIJ.run('Duplicate...', 'duplicate range=1-8000'); dish1Concat = [];
            dish1Concat = 'Dish1 Cell1 1st 8000 Frames.tif';
            MIJ.run('Save',sprintf('save=[%s\\%s]',fileOpen,dish1Concat));
            MIJ.selectWindow('Concatenated Stacks');
            MIJ.run('Duplicate...', 'duplicate range=8001-16000'); dish1Concat = [];
            dish1Concat = 'Dish1 Cell1 2nd 8000 Frames.tif';
            MIJ.run('Save',sprintf('save=[%s\\%s]',fileOpen,dish1Concat));
            MIJ.closeAllWindows; % close all the windows
        elseif 2 < gbSize <= 4 % if file size is inbetween 2-4gb, split into 4ths
            MIJ.run('Duplicate...', 'duplicate range=1-4000'); dish1Concat = [];
            dish1Concat = 'Dish1 Cell1 1st 4000 Frames.tif';
            MIJ.run('Save',sprintf('save=[%s\\%s]',fileOpen,dish1Concat));
            MIJ.selectWindow('Concatenated Stacks');
            MIJ.run('Duplicate...', 'duplicate range=4001-8000'); dish1Concat = [];
            dish1Concat = 'Dish1 Cell1 2nd 4000 Frames.tif';
            MIJ.run('Save',sprintf('save=[%s\\%s]',fileOpen,dish1Concat));
            MIJ.selectWindow('Concatenated Stacks');
            MIJ.run('Duplicate...', 'duplicate range=8001-12001'); dish1Concat = [];
            dish1Concat = 'Dish1 Cell1 3rd 4000 Frames.tif';
            MIJ.run('Save',sprintf('save=[%s\\%s]',fileOpen,dish1Concat));
            MIJ.selectWindow('Concatenated Stacks');
            MIJ.run('Duplicate...', 'duplicate range=12001-16000'); dish1Concat = [];
            dish1Concat = 'Dish1 Cell1 4th 4000 Frames.tif';
            MIJ.run('Save',sprintf('save=[%s\\%s]',fileOpen,dish1Concat));
            MIJ.closeAllWindows; % close all the windows
        elseif 4 < gbSize <= 8 % if file size is inbetween 4-8gb, split into 8ths
            MIJ.run('Duplicate...', 'duplicate range=1-2000'); dish1Concat = [];
            dish1Concat = 'Dish1 Cell1 1st 2000 Frames.tif'; % 1st 2000
            MIJ.run('Save',sprintf('save=[%s\\%s]',fileOpen,dish1Concat));
            MIJ.selectWindow('Concatenated Stacks');
            MIJ.run('Duplicate...', 'duplicate range=2001-4000'); dish1Concat = [];
            dish1Concat = 'Dish1 Cell1 2nd 2000 Frames.tif'; % 2nd 2000
            MIJ.run('Save',sprintf('save=[%s\\%s]',fileOpen,dish1Concat));
            MIJ.selectWindow('Concatenated Stacks');
            MIJ.run('Duplicate...', 'duplicate range=4001-6000'); dish1Concat = [];
            dish1Concat = 'Dish1 Cell1 3rd 2000 Frames.tif'; % 3rd 2000
            MIJ.run('Save',sprintf('save=[%s\\%s]',fileOpen,dish1Concat));
            MIJ.selectWindow('Concatenated Stacks');
            MIJ.run('Duplicate...', 'duplicate range=6001-8000'); dish1Concat = [];
            dish1Concat = 'Dish1 Cell1 4th 4000 Frames.tif'; % 4th 2000
            MIJ.run('Save',sprintf('save=[%s\\%s]',fileOpen,dish1Concat));
            MIJ.selectWindow('Concatenated Stacks');
            MIJ.run('Duplicate...', 'duplicate range=8001-10000'); dish1Concat = [];
            dish1Concat = 'Dish1 Cell1 5th 4000 Frames.tif'; % 5th 2000
            MIJ.run('Save',sprintf('save=[%s\\%s]',fileOpen,dish1Concat));
            MIJ.selectWindow('Concatenated Stacks');
            MIJ.run('Duplicate...', 'duplicate range=10001-12000'); dish1Concat = [];
            dish1Concat = 'Dish1 Cell1 6th 4000 Frames.tif'; % 6th 2000
            MIJ.run('Save',sprintf('save=[%s\\%s]',fileOpen,dish1Concat));
            MIJ.selectWindow('Concatenated Stacks');
            MIJ.run('Duplicate...', 'duplicate range=12001-14000'); dish1Concat = [];
            dish1Concat = 'Dish1 Cell1 7th 4000 Frames.tif'; % 7th 2000
            MIJ.run('Save',sprintf('save=[%s\\%s]',fileOpen,dish1Concat));
            MIJ.selectWindow('Concatenated Stacks');
            MIJ.run('Duplicate...', 'duplicate range=14001-16000'); dish1Concat = [];
            dish1Concat = 'Dish1 Cell1 8th 4000 Frames.tif'; % 8th 2000
            MIJ.run('Save',sprintf('save=[%s\\%s]',fileOpen,dish1Concat));
            MIJ.closeAllWindows; % close all the windows
        end
    end
end
end