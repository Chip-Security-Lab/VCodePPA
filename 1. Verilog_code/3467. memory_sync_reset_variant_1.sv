//SystemVerilog
module memory_sync_reset #(parameter DEPTH = 8, WIDTH = 8)(
  input clk, reset,
  input [WIDTH-1:0] data_in,
  input [$clog2(DEPTH)-1:0] addr,
  input write_en,
  input valid_in,
  output valid_out,
  output reg [WIDTH-1:0] data_out
);
  // Memory array
  reg [WIDTH-1:0] mem [0:DEPTH-1];
  
  // Lookup table for 8-bit subtraction
  reg [7:0] lut_diff [0:255][0:255]; 
  
  // Pipeline stage 1 registers
  reg [$clog2(DEPTH)-1:0] addr_stage1;
  reg write_en_stage1;
  reg [WIDTH-1:0] data_in_stage1;
  reg [WIDTH-1:0] mem_data_stage1;
  reg valid_stage1;
  
  // Pipeline stage 2 registers
  reg [7:0] operand_a_stage2;
  reg [7:0] operand_b_stage2;
  reg write_en_stage2;
  reg [WIDTH-1:0] mem_data_stage2;
  reg valid_stage2;
  
  // Pipeline stage 3 registers
  reg [7:0] result_stage3;
  reg [WIDTH-1:0] mem_data_stage3;
  reg valid_stage3;
  
  integer i, j, k;
  
  // Initialize the subtraction lookup table
  initial begin
    for (j = 0; j < 256; j = j + 1) begin
      for (k = 0; k < 256; k = k + 1) begin
        lut_diff[j][k] = j - k; // Precompute all possible differences
      end
    end
  end
  
  // Pipeline Stage 1: Memory access and data preparation
  always @(posedge clk) begin
    if (reset) begin
      addr_stage1 <= 0;
      write_en_stage1 <= 0;
      data_in_stage1 <= 0;
      mem_data_stage1 <= 0;
      valid_stage1 <= 0;
      
      // Initialize memory on reset
      for (i = 0; i < DEPTH; i = i + 1)
        mem[i] <= 0;
    end else begin
      addr_stage1 <= addr;
      write_en_stage1 <= write_en;
      data_in_stage1 <= data_in;
      mem_data_stage1 <= (addr < DEPTH) ? mem[addr] : 0;
      valid_stage1 <= valid_in;
      
      // Memory write operation
      if (write_en && valid_in && addr < DEPTH)
        mem[addr] <= data_in;
    end
  end
  
  // Pipeline Stage 2: Operand selection
  always @(posedge clk) begin
    if (reset) begin
      operand_a_stage2 <= 0;
      operand_b_stage2 <= 0;
      write_en_stage2 <= 0;
      mem_data_stage2 <= 0;
      valid_stage2 <= 0;
    end else begin
      write_en_stage2 <= write_en_stage1;
      valid_stage2 <= valid_stage1;
      
      if (write_en_stage1) begin
        // Write mode operands
        operand_a_stage2 <= data_in_stage1;
        operand_b_stage2 <= mem_data_stage1;
        mem_data_stage2 <= data_in_stage1; // Forward written data
      end else begin
        // Read mode operands
        operand_a_stage2 <= mem_data_stage1;
        operand_b_stage2 <= 8'h01; // Constant for demonstration
        mem_data_stage2 <= mem_data_stage1; // Forward read data
      end
    end
  end
  
  // Pipeline Stage 3: Lookup table operation and output preparation
  always @(posedge clk) begin
    if (reset) begin
      result_stage3 <= 0;
      mem_data_stage3 <= 0;
      valid_stage3 <= 0;
    end else begin
      // Perform subtraction using lookup table
      result_stage3 <= lut_diff[operand_a_stage2][operand_b_stage2];
      mem_data_stage3 <= mem_data_stage2;
      valid_stage3 <= valid_stage2;
    end
  end
  
  // Final stage: Output assignment
  always @(posedge clk) begin
    if (reset) begin
      data_out <= 0;
    end else begin
      data_out <= mem_data_stage3;
    end
  end
  
  // Valid output signal
  assign valid_out = valid_stage3;
  
endmodule