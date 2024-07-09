function A = hInsert(A, b, locations)
%hInsert performs a horizontal insert of b at locations into A - in
% otherwords, if you want to insert a single vector b into A at 9, then you
% will find b at A(:,9). This loses some clarity in the event of inserting
% two different vectors for insertion as the act of inserting the first will
% necessarily change the location where the second will be inserted.
% Therefore, the references should go to where in the current array you would
% like to have the inserted vector. b must be as wide as there are locations or
% else and error will occur. Additionally, A must be as wide as there are
% locations or else an error may occur, the error will occur when an insert
% is attempted greater than the width plus one (the width plus one
% operation being the append operation). The last bit of functionality to
% this is the insertion of multiple vectors at a single point, which is
% done by repeating a location, the initial order is preserved. So if 

if length(locations)~=size(b,2)
    error('The number of locations is different than the number of vectors to be inserted');
elseif max(locations) > size(A,2)+1
    error('You are trying to insert a vector at a point not inside the array')
elseif size(A,1)~=size(b,1)
    error('The inserted vector and array do not have common lengths')
end

[locations, indices] = sort(locations);

b = b(:,indices);

for i = 1:length(locations)
    left = A(:,1:locations(i)-1);
    right = A(:,locations(i):end);
    A = [left b(:,i) right];
    locations = locations + 1;
end