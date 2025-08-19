//SystemVerilog
module moore_3state_pipeline #(parameter WIDTH = 8)(
  input  clk,
  input  rst,
  input  valid_in,
  input  [WIDTH-1:0] data_in,
  output reg [WIDTH-1:0] data_out,
  output reg valid_out
);
  reg [1:0] state, next_state;
  localparam S0 = 2'b00,
             S1 = 2'b01,
             S2 = 2'b10;
  reg [WIDTH-1:0] stage0, stage1;

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state     <= S0;
      stage0    <= 0;
      stage1    <= 0;
      data_out  <= 0;
    end else begin
      state <= next_state;
      
      if (state == S0) begin
        if (valid_in) stage0 <= data_in;
      end else if (state == S1) begin
        stage1 <= stage0;
      end else if (state == S2) begin
        data_out <= stage1;
      end
    end
  end

  always @* begin
    valid_out = 1'b0;
    next_state = state; // 默认保持当前状态
    
    if (state == S0) begin
      if (valid_in) next_state = S1;
    end else if (state == S1) begin
      next_state = S2;
    end else if (state == S2) begin
      valid_out = 1'b1;
      next_state = S0;
    end
  end
endmodule