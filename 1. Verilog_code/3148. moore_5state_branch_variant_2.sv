//SystemVerilog
module moore_5state_branch(
  input  clk,
  input  rst,
  input  sel,
  output reg pathA,
  output reg pathB
);
  reg [2:0] state, next_state;
  reg [2:0] next_state_buf1, next_state_buf2;
  localparam S0=3'b000, S1=3'b001, S2=3'b010, S3=3'b011, S4=3'b100;

  // Optimized state transition logic using signed multiplication
  wire [2:0] state_transition;
  wire [2:0] sel_ext = {2'b0, sel};
  wire [2:0] state_plus_1 = state + 3'b001;
  wire [2:0] state_plus_2 = state + 3'b010;
  
  assign state_transition = (state == S0) ? 
                           (sel_ext * state_plus_1) : 
                           ((state == S1) ? state_plus_2 : 
                           ((state == S2) ? state_plus_2 : S0));

  // Buffer registers for high fanout signal next_state
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      next_state_buf1 <= S0;
      next_state_buf2 <= S0;
    end
    else begin
      next_state_buf1 <= state_transition;
      next_state_buf2 <= state_transition;
    end
  end

  // State register update using buffered next_state
  always @(posedge clk or posedge rst) begin
    if (rst) state <= S0;
    else     state <= next_state_buf1;
  end

  // Output logic using buffered next_state
  always @* begin
    pathA = 1'b0;
    pathB = 1'b0;
    case (next_state_buf2)
      S1: pathA = 1'b1;
      S2: pathB = 1'b1;
      default: ;
    endcase
  end
endmodule