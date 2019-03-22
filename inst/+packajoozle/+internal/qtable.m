## Copyright (C) 2019 Andrew Janke
##
## This program is free software; you can redistribute it and/or modify
## it under the terms of the GNU General Public License as published by
## the Free Software Foundation; either version 2 of the License, or
## (at your option) any later version.
##
## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.   See the
## GNU General Public License for more details.
##
## You should have received a copy of the GNU General Public License
## along with this program; If not, see <http://www.gnu.org/licenses/>.

## -*- texinfo -*-
## @deftypefn {Class Constructor} {obj =} qtable (...)
## Quasi-table object
##
## Qtable is a "quasi-table" class: it's like a table, but it's dumb and
## only supports the most basic data holding and rearrangement operations.
## You can think of it as a glorified struct with tabular pretty-printing
## support.
##
## Limitations of this class:
##  - A qtable object is a scalar object; it does not emulate a 2-D array
##    like Matlab's @@table does. 
##  - The columns ("variables") must be column vectors; they may not be n-wide
##    arrays.
##  - No joins, merges, set operations, or other inter-table operations are
##    defined.
##
## @end deftypefn

## This class steals from apjanke's real attempt at a table implementation 
## at https://github.com/apjanke/octave-table wherever it sees fit.

classdef qtable

  properties
    col_names = {}
    col_values = {}
  endproperties

  methods
    function this = qtable (varargin)
      if nargin == 0
        return
      endif
      # qtable (struct)
      if nargin == 1 && isstruct (varargin{1})
        s = varargin{1};
        this.col_names = fieldnames (s);
        c = struct2cell (s);
        for i = 1:numel (c)
          c{i} = c{i}(:);
        endfor
        this.col_values = c;
        this = this.validate;
        return
      endif
      # qtable (col_values, col_names)
      if nargin == 2 && iscell (varargin{1}) && iscellstr (varargin{2})
        this.col_values = varargin{1};
        this.col_names = varargin{2};
        this = this.validate;
        return
      endif
      # Oh well...
      error ("qtable: unrecognized constructor argument format");
    endfunction

    function this = validate (this)
      if numel (this.col_names) != numel (this.col_values)
        error ("qtable: number of col names (%d) and col values (%d) do not match", ...
          numel (this.col_names), numel (this.col_values));
      endif
      this.col_names = this.col_names(:)';
      n_rows = numel (this.col_values{1});
      for i = 1:numel (this.col_values)
        cv = this.col_values{i};
        if ! iscolumn (cv)
          error ("qtable: column %d (%s) is not a column vector; got a %s", i, ...
            this.col_names{i}, size2str (size (cv)));
        endif
        n_i = numel (cv);
        if n_i != n_rows
          error ("qtable: column size mismatch: this has %d rows, but column %d has %d values", ...
            n_rows, i, n_i);
        endif
      endfor
    endfunction

    function out = nrows (this)
      out = numel (this.col_values{1});
    endfunction

    function out = ncols (this)
      out = numel (this.col_names);
    endfunction

    function out = restrict (this, ix)
      out = this;
      for i = 1:this.ncols
        out.col_values{i} = this.col_values{i}(ix);
      endfor
    endfunction

    function out = project (this, cols)
      out = this;
      if isnumeric (cols) || islogical (cols)
        ix = cols;
        out.col_names = this.col_names(ix);
        out.col_values = this.col_values(ix);
      elseif iscellstr (cols)
        [tf, loc] = ismember (cols, this.col_names);
        if ! all (tf)
          error ("qtable: no such columns in this: %s", strjoin (cols(!tf), ", "));
        endif
        out.col_names = this.col_names(loc);
        out.col_values = this.col_values(loc);
      endif
    endfunction

    function out = tablesize (this)
      mustBeScalar (this);
      out = [nrows(this) ncols(this)];
    endfunction

    function prettyprint (this)
      %PRETTYPRINT Display table values, formatted as a table
      if isempty (this)
        fprintf ('Empty %s %s\n', size2str (size (this)), class (this));
        return;
      end
      nVars = ncols (this);
      varNames = this.col_names;
      % Here, "cols" means output columns, not data columns. Each data variable
      % will be displayed in a single output column.
      colNames = varNames;
      colStrs = cell (1, nVars);
      colWidths = NaN (1, nVars);
      for iVar = 1:numel (this.col_values)
        vals = this.col_values{iVar};
        strs = dispstrs (vals);
        lines = cell (ncols(this), 1);
        for iRow = 1:size (strs, 1)
          lines{iRow} = strjoin (strs(iRow,:), '   ');
        end
        colStrs{iVar} = lines;
        colWidths(iVar) = max (cellfun ('numel', lines));
      end
      colWidths;
      nameWidths = cellfun ('numel', varNames);
      colWidths = max ([nameWidths; colWidths]);
      totalWidth = sum (colWidths) + 4 + (3 * (nVars - 1));
      elementStrs = cat (2, colStrs{:});
      
      rowFmts = cell (1, nVars);
      for i = 1:nVars
        rowFmts{i} = ['%-' num2str(colWidths(i)) 's'];
      end
      rowFmt = ['| ' strjoin(rowFmts, ' | ')  ' |' sprintf('\n')];
      fprintf ('%s\n', repmat ('-', [1 totalWidth]));
      fprintf (rowFmt, varNames{:});
      fprintf ('%s\n', repmat ('-', [1 totalWidth]));
      for i = 1:nrows (this)
        fprintf (rowFmt, elementStrs{i,:});
      end
      fprintf ('%s\n', repmat ('-', [1 totalWidth]));
    end
    

  endmethods

endclassdef