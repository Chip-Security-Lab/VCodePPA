//SystemVerilog
module moore_4state_ring #(parameter WIDTH = 4)(
  input  clk,
  input  rst,
  output reg [WIDTH-1:0] ring_out
);
  reg [1:0] state_stage1, state_stage2, next_state_stage1, next_state_stage2;
  localparam S0 = 2'b00,
             S1 = 2'b01,
             S2 = 2'b10,
             S3 = 2'b11;

  // Buffer for high fanout signal next_state
  reg [1:0] next_state_buf_stage1, next_state_buf_stage2;

  // Stage 1: State Register
  always @(posedge clk or posedge rst) begin
    if (rst) begin
      state_stage1 <= S0;
      state_stage2 <= S0;
    end else begin
      state_stage1 <= next_state_buf_stage1; // Use buffered next_state
      state_stage2 <= state_stage1; // Pass state to next stage
    end
  end

  // Stage 2: Next State Logic
  always @* begin
    case (state_stage1)
      S0: next_state_buf_stage1 = S1;
      S1: next_state_buf_stage1 = S2;
      S2: next_state_buf_stage1 = S3;
      S3: next_state_buf_stage1 = S0;
    endcase
  end

  // Stage 3: Output Logic
  always @* begin
    case (state_stage2)
      S0: ring_out = 4'b0001;
      S1: ring_out = 4'b0010;
      S2: ring_out = 4'b0100;
      S3: ring_out = 4'b1000;
    endcase
  end
endmodule