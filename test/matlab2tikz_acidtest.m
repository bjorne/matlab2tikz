% =========================================================================
% *** FUNCTION matlab2xxx_acidtest
% ***
% *** Choose the EPS output driver as the PDF will yield a the plot on a
% *** full page, rather than nicely cropped around the figure.
% ***
% =========================================================================  
% ***
% *** Copyright (c) 2008--2011, Nico Schl\"omer <nico.schloemer@gmail.com>
% *** All rights reserved.
% ***
% *** Redistribution and use in source and binary forms, with or without 
% *** modification, are permitted provided that the following conditions are 
% *** met:
% ***
% ***    * Redistributions of source code must retain the above copyright 
% ***      notice, this list of conditions and the following disclaimer.
% ***    * Redistributions in binary form must reproduce the above copyright 
% ***      notice, this list of conditions and the following disclaimer in 
% ***      the documentation and/or other materials provided with the distribution
% ***
% *** THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
% *** AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
% *** IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
% *** ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE 
% *** LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
% *** CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
% *** SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
% *** INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
% *** CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
% *** ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
% *** POSSIBILITY OF SUCH DAMAGE.
% ***
% =========================================================================
function matlab2tikz_acidtest( varargin )

  % In which environment are we?
  version_data = ver;
  if length( version_data ) > 1 % assume MATLAB
      env = 'MATLAB(R)';
  elseif strcmp( version_data.Name, 'Octave' )
      env = 'GNU Octave';
  else
      error( 'Unknown environment. Need MATLAB(R) or GNU Octave.' )
  end

  % -----------------------------------------------------------------------
  matlab2tikzOpts = matlab2tikzInputParser;

  matlab2tikzOpts = matlab2tikzOpts.addOptional( matlab2tikzOpts, ...
                                                 'testFunctionIndices', ...
                                                 [], @isfloat );

  matlab2tikzOpts = matlab2tikzOpts.parse( matlab2tikzOpts, varargin{:} );
  % -----------------------------------------------------------------------

  % first, initialize the tex output
  texfile = 'tex/acid.tex';
  fh = fopen( texfile, 'w' );
  texfile_init( fh );

  % query the number of test functions
  [m, n] = testfunctions(0);

  if ~isempty(matlab2tikzOpts.Results.testFunctionIndices)
      indices = matlab2tikzOpts.Results.testFunctionIndices;
      % kick out the illegal stuff
      I = find(indices>=1) & find(indices<=n);
      indices = indices(I);
  else
      indices = 1:n;
  end

  for k = indices

      fprintf('Treating test function no. %d... ', k );

      % open a window
      fig_handle = figure;

      % plot the figure
      desc = testfunctions( k );

      % plot not sucessful
      if isempty(desc)
          close( fig_handle );
          continue
      end

      pdf_file = sprintf( 'data/test%d-reference' , k );
      gen_file = sprintf( 'data/test%d-converted.tikz', k );

      tic;

      % now, test matlab2xxx
      matlab2tikz( gen_file, 'silent', false,...
                             'relativePngPath', '../data/', ...
                             'width', '\figurewidth' );

      if strcmp( env, 'MATLAB(R)' )
          % Create a cropped print.
          savefig( pdf_file, 'pdf' );
      elseif strcmp( env, 'GNU Octave' )
          % In Octave, figures are automatically cropped when using print().
          print( strcat(pdf_file,'.pdf'), '-dpdf' );
          pause( 1.0 )
      else
          error( 'Unknown environment. Need MATLAB(R) or GNU Octave.' )
      end

      % ...and finally write the bits to the LaTeX file
      texfile_addtest( fh, pdf_file, gen_file, desc );

      % After 10 floats, but a \clearpage to avoid
      %
      %   ! LaTeX Error: Too many unprocessed floats.
      if ~mod(k,10)
          fprintf( fh, '\\clearpage\n\n' );
      end

      close( fig_handle );

      elapsedTime = toc;
      fprintf( 'done (%4.2fs).\n\n', elapsedTime );
  end

  % now, finish off the file and close file and window
  texfile_finish( fh );
  fclose( fh );

end
% =========================================================================
% *** END OF FUNCTION matlab2xxx_acidtest
% =========================================================================



% =========================================================================
% *** FUNCTION texfile_init
% =========================================================================
function texfile_init( texfile_handle )

  fprintf( texfile_handle                                             , ...
           [ '\\documentclass{scrartcl}\n\n'                          , ...
             '\\usepackage{graphicx}\n'                               , ...
             '\\usepackage{tikz}\n'                                   , ...
             '\\usetikzlibrary{plotmarks}\n\n'                        , ...
             '\\usepackage{pgfplots}\n'                               , ...
             '\\pgfplotsset{compat=newest}\n\n'                       , ...
             '\\newlength\\figurewidth\n'                             , ...
             '\\setlength\\figurewidth{7cm}\n\n'                      , ...
             '\\begin{document}\n\n'         ] );

end
% =========================================================================
% *** END OF FUNCTION texfile_init
% =========================================================================



% =========================================================================
% *** FUNCTION texfile_finish
% =========================================================================
function texfile_finish( texfile_handle )

  fprintf( texfile_handle, '\\end{document}' );

end
% =========================================================================
% *** END OF FUNCTION texfile_finish
% =========================================================================



% =========================================================================
% *** FUNCTION texfile_addtest
% ***
% *** Actually add the piece of LaTeX code that'll later be used to display
% *** the given test.
% ***
% =========================================================================
function texfile_addtest( texfile_handle, ref_file, gen_file, desc )

  fprintf ( texfile_handle                                            , ...
            [ '\\begin{figure}\n'                                     , ...
              '\\centering\n'                                         , ...
              '\\begin{tabular}{cc}\n'                                , ...
              '\\includegraphics[width=\\figurewidth]{../%s}\n'       , ...
              '&\n'                                                   , ...
              '\\input{../%s}\\\\\n'                                  , ...
              'reference rendering & generated\n'                     , ...
              '\\end{tabular}\n'                                      , ...
              '\\caption{%s}\n'                                       , ...
              '\\end{figure}\n\n'                                    ], ...
              ref_file, gen_file, desc                                  ...
          );

end
% =========================================================================
% *** END OF FUNCTION texfile_addtest
% =========================================================================
