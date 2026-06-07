library ieee;
  use ieee.std_logic_1164.all;
  use ieee.numeric_std.all;

library std;
  use std.textio.all;

package CommandLoggerPkg is
  constant CMD_MAX : natural := 65535;
  subtype CmdIdType is natural range 0 to CMD_MAX;

  type CommandLoggerPType is protected
    procedure LogCommandWord(Id : in CmdIdType);
    procedure WriteTestResults(FileName : in string; TestName : in string);
    procedure ComputeTotals(FileName : in string);
    procedure WriteTestYaml(FileName : in string; TestName : in string);
    procedure WriteTotalsYaml(FileName : in string);
    procedure Clear;
  end protected;

  procedure LogCommandWord(Id : in CmdIdType);
  procedure WriteTestResults(FileName : in string; TestName : in string);
  procedure ComputeTotals(FileName : in string);
  procedure WriteTestYaml(FileName : in string; TestName : in string);
  procedure WriteTotalsYaml(FileName : in string);
  procedure Clear;
end package;

package body CommandLoggerPkg is
  type CommandLoggerPType is protected body
    variable Counts : integer_vector(0 to CMD_MAX) := (others => 0);
    ------------------------------------------------------
    -- Increment usage count (thread-safe)
    ------------------------------------------------------
    procedure LogCommandWord(Id : in CmdIdType) is
    begin
      Counts(Id) := Counts(Id) + 1;
    end procedure;

    ------------------------------------------------------
    -- WriteTestResults: fully expand CSV matrix
    ------------------------------------------------------
    procedure WriteTestResults(FileName : in string; TestName : in string) is
      file f_out : text;
      variable L        : line;
    begin
      --------------------------------------------------
      -- Write new CSV with all test columns (0-filled)
      --------------------------------------------------
      file_open(f_out, FileName & ".csv", write_mode);

      -- Header row
      write(L, string'("CommandID"));
      write(L, string'(",Count"));
      writeline(f_out, L);

      -- Count data
      for CmdIndex in 0 to CMD_MAX loop
        write(L, integer'image(CmdIndex));
        write(L, string'(","));
        write(L, integer'image(Counts(CmdIndex)));
        writeline(f_out, L);
      end loop;
      file_close(f_out);

    end procedure;

    ------------------------------------------------------
    -- ComputeTotals: sum each row across all tests
    ------------------------------------------------------
    procedure ComputeTotals(FileName : in string) is
      file f_in, f_out : text;
      variable L        : line;
      variable Cmd, Val : integer;
      variable Totals   : integer_vector(0 to CMD_MAX) := (others => 0);
      variable FileStatus     : file_open_status;
      variable Good           : boolean;
    begin
      file_open(FileStatus, f_in, FileName & ".csv", read_mode);
      if FileStatus /= OPEN_OK then
        return; -- File doesn't exist, nothing to compute
      end if;

      readline(f_in, L); -- skip header
      while not endfile(f_in) loop
        readline(f_in, L);
        -- Read command ID
        read(L, Cmd, Good);
        if not Good then
          exit; -- Invalid line format
        end if;

        -- Read all remaining values on this line and sum them
        while true loop
          read(L, Val, Good);
          if Good then
            Totals(Cmd) := Totals(Cmd) + Val;
          else
            exit; -- No more valid numbers on this line
          end if;
        end loop;
      end loop;
      file_close(f_in);

      file_open(f_out, FileName & "_Totals.csv", write_mode);
      write(L, string'("CommandID,TotalCount"));
      writeline(f_out, L);
      for CmdIndex in Totals'range loop
        if Totals(CmdIndex) /= 0 then
          write(L, integer'image(CmdIndex));
          write(L, string'(","));
          write(L, integer'image(Totals(CmdIndex)));
          writeline(f_out, L);
        end if;
      end loop;
      file_close(f_out);
    end procedure;
    ------------------------------------------------------
    -- WriteTestYaml : Create YAML report for a single test
    ------------------------------------------------------
    procedure WriteTestYaml(FileName : in string; TestName : in string) is
      file fy : text;
      variable L : line;
    begin
      file_open(fy, "Reports/scripts_RunTest_" & TestName & "/" & FileName & ".yml", write_mode);
    
      -- YAML Header
      write(L, string'("---"));
      writeline(fy, L);
      write(L, string'("OSVVM_Result: PASS"));
      writeline(fy, L);
      write(L, string'("OSVVM_TestName: " & TestName));
      writeline(fy, L);
      write(L, string'("CommandWordMetrics:"));
      writeline(fy, L);

      -- Dump non-zero command counts
      for CmdIndex in Counts'range loop
        if Counts(CmdIndex) /= 0 then
          write(L, string'("  - ID: "));
          write(L, integer'image(CmdIndex));
          writeline(fy, L);
          write(L, string'("    Count: "));
          write(L, integer'image(Counts(CmdIndex)));
          writeline(fy, L);
        end if;
      end loop;

      file_close(fy);
    end procedure;


    ------------------------------------------------------
    -- WriteTotalsYaml : Create YAML for overall totals
    ------------------------------------------------------
    procedure WriteTotalsYaml(FileName : in string) is
      file fy : text;
      variable L : line;
      file f_in : text;
      variable Cmd, Val : integer;
      variable Totals : integer_vector(0 to CMD_MAX) := (others => 0);
      variable FileStatus : file_open_status;
      variable Good : boolean;
    begin
      -- read CSV totals
      file_open(FileStatus, f_in, FileName & "_Totals.csv", read_mode);
      if FileStatus /= OPEN_OK then
        return; -- File doesn't exist, nothing to write
      end if;

      readline(f_in, L);  -- skip header
      while not endfile(f_in) loop
        readline(f_in, L);
        -- Read command ID
        read(L, Cmd, Good);
        if not Good then
          exit; -- Invalid line format
        end if;
        -- Read total value
        read(L, Val, Good);
        if Good then
          Totals(Cmd) := Val;
        end if;
      end loop;
      file_close(f_in);

      -- Write YAML file
      file_open(fy, "Reports/Mil1553/" & FileName & "/" & FileName & "_Totals.yml", write_mode);
      write(L, string'("---"));
      writeline(fy, L);
      write(L, string'("OSVVM_Result: PASS"));
      writeline(fy, L);
      write(L, string'("OSVVM_TestName: Totals"));
      writeline(fy, L);
      write(L, string'("CommandWordTotals:"));
      writeline(fy, L);

      for i in Totals'range loop
        if Totals(i) /= 0 then
          write(L, string'("  - ID: "));
          write(L, integer'image(i));
          writeline(fy, L);
          write(L, string'("    TotalCount: "));
          write(L, integer'image(Totals(i)));
          writeline(fy, L);
        end if;
      end loop;

      file_close(fy);
    end procedure;
    ------------------------------------------------------
    -- Clear current counters
    ------------------------------------------------------
    procedure Clear is
    begin
      Counts := (others => 0);
    end procedure;

  end protected body CommandLoggerPType;

  shared variable CommandLogger : CommandLoggerPType;

  procedure LogCommandWord(Id : in CmdIdType) is
  begin
    CommandLogger.LogCommandWord(Id);
  end procedure LogCommandWord;

  procedure WriteTestResults(FileName : in string; TestName : in string) is
  begin
    CommandLogger.WriteTestResults(FileName, TestName);
  end procedure WriteTestResults;

  procedure ComputeTotals(FileName : in string) is
  begin
    CommandLogger.ComputeTotals(FileName);
  end procedure ComputeTotals;

  procedure WriteTestYaml(FileName : in string; TestName : in string) is
  begin
    CommandLogger.WriteTestYaml(FileName, TestName);
  end procedure WriteTestYaml;

  procedure WriteTotalsYaml(FileName : in string) is
  begin
    CommandLogger.WriteTotalsYaml(FileName);
  end procedure WriteTotalsYaml;

  procedure Clear is
  begin
    CommandLogger.Clear;
  end procedure Clear;
end package body;
