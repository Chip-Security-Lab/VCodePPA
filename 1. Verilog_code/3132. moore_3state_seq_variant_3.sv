//SystemVerilog
module moore_3state_seq #(parameter WIDTH = 4)(
  input  clk,
  input  rst,
  output reg [WIDTH-1:0] seq_out
);
  reg [1:0] state, next_state;
  reg [1:0] state_buf;
  reg [WIDTH-1:0] seq_out_buf;
  localparam S0 = 2'b00,
             S1 = 2'b01,
             S2 = 2'b10;

  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state <= S0;
      seq_out <= {WIDTH{1'b0}};
    end else begin
      state <= state_buf;
      seq_out <= seq_out_buf;
    end
  end

  always @* begin
    case(state)
      S0: next_state = S1;
      S1: next_state = S2;
      S2: next_state = S0;
      default: next_state = S0;
    endcase
  end

  always @* begin
    state_buf = next_state;
  end

  always @* begin
    case(state)
      S0: seq_out_buf = {WIDTH{1'b0}};
      S1: seq_out_buf = {WIDTH{1'b1}};
      S2: seq_out_buf = {{(WIDTH/2){2'b10}} , {(WIDTH%2){1'b0}}};
      default: seq_out_buf = {WIDTH{1'b0}};
    endcase
  end
endmodule