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

  // Combined state and data management
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state     <= S0;
      stage0    <= 0;
      stage1    <= 0;
      data_out  <= 0;
      valid_out <= 0;
    end else begin
      state <= next_state;
      case (state)
        S0: if (valid_in) stage0 <= data_in;
        S1: stage1 <= stage0;
        S2: begin
              data_out <= stage1;
              valid_out <= 1'b1;
            end
        default: valid_out <= 1'b0;
      endcase
    end
  end

  // Optimized next state logic
  always @* begin
    case (state)
      S0: next_state = valid_in ? S1 : S0;
      S1: next_state = S2;
      S2: next_state = S0;
      default: next_state = S0;
    endcase
  end

endmodule