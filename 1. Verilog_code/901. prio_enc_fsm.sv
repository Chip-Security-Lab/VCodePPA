module prio_enc_fsm #(parameter WIDTH=6)(
  input clk, rst,
  input [WIDTH-1:0] in,
  output reg [$clog2(WIDTH)-1:0] addr
);
// 使用参数化的位宽
localparam IDLE = 1'b0;
localparam SCAN = 1'b1;
reg state;
integer i;

always @(posedge clk) begin
  if(rst) begin
    state <= IDLE;
    addr <= 0;
  end else case(state)
    IDLE: if(|in) begin
      state <= SCAN;
      addr <= 0;
    end
    SCAN: begin
      for(i=0; i<WIDTH; i=i+1)
        if(in[i]) addr <= i[$clog2(WIDTH)-1:0];
      state <= IDLE;
    end
    default: state <= IDLE;
  endcase
end
endmodule