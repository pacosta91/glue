function status = sendOutlookMail(to,subject,body,attachments)
% Sends email using MS Outlook. The format of the function is similar to the SENDMAIL command. 
% 
% Syntax:   
%   status = function sendOutlookMail(to,subject,body,attachments)       
%
% Inputs:
%   to - The email address of the recipient
%   subject - The subject of the email
%   body - The body of the email
%   attachments -   Additional files to send; note that the path and filename
%                   must be included.
%
% Outputs:
%   status - 1 if successful; 0 if not 
%
% CFR Requirement(s) Implemented:
%   None
%
% Examples: 
% The first will example includes a link, the second a picture.
% sendOutlookMail('test@mathworks.com','Test link','Test message including
% a <A HREF=<http://www.mathworks.com>>Link</A>', {'C:\attachment1.txt'
% 'C:\attachment2.txt'}); sendOutlookMail('test@mathworks.com','Test
% image', 'Test message including an image <img
% src="<http://t3.gstatic.com/images?q=tbn:ANd9GcQ-g_C_RAP7xbdz_Da-GK20YeycTzN2JkZotcIgx22dH2v4cBULmhVdLnc
% http://t3.gstatic.com/images?q=tbn:ANd9GcQ-g_C_RAP7xbdz_Da-GK20YeycTzN2JkZotcIgx22dH2v4cBULmhVdLnc">>')
%
% Other m-files required: 
%   None
%
% Subfunctions: 
%   None
%
% MAT-files required: 
%   None
%

% Author:           Eric Simon
% File Version:     1.0
% Revision History:   
% 1.0   09/29/2014  Original File
%
% Based on http://www.mathworks.com/matlabcentral/answers/94446-can-i-send-e-mail-through-matlab-using-microsoft-outlook

% =========================================================================

% Create object and set parameters.
h = actxserver('outlook.Application');
mail = h.CreateItem('olMail');

mail.Subject = subject;
mail.To = to;
mail.BodyFormat = 'olFormatHTML';
mail.HTMLBody = body;

% Add attachments, if specified.
if nargin == 4
      for i = 1:length(attachments)
          mail.attachments.Add(attachments{i});
      end
end

% Send message and release object.
mail.Send;
h.release;