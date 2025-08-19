//SystemVerilog
// Top level module with pipelined data path
module multi_assign(
  input clk,
  input rst_n,
  input [3:0] val1, val2,
  output reg [4:0] sum,
  output reg carry
);

  // Pipeline stage 1: Input registers
  reg [3:0] val1_reg, val2_reg;
  
  // Pipeline stage 2: Partial sum and carry computation
  reg [3:0] partial_sum_reg;
  reg carry_out_reg;
  
  // Pipeline stage 1: Input sampling
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      val1_reg <= 4'b0;
      val2_reg <= 4'b0;
    end else begin
      val1_reg <= val1;
      val2_reg <= val2;
    end
  end

  // Pipeline stage 2: Computation
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      partial_sum_reg <= 4'b0;
      carry_out_reg <= 1'b0;
    end else begin
      // Adder computation
      partial_sum_reg <= val1_reg + val2_reg;
      
      // Carry computation
      carry_out_reg <= (val1_reg[3] & val2_reg[3]) | 
                      ((val1_reg[3] | val2_reg[3]) & (partial_sum_reg[3]));
    end
  end

  // Pipeline stage 3: Output generation
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      sum <= 5'b0;
      carry <= 1'b0;
    end else begin
      sum <= {carry_out_reg, partial_sum_reg};
      carry <= carry_out_reg;
    end
  end

endmodule