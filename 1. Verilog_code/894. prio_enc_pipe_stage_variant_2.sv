//SystemVerilog
module prio_enc_pipe_stage #(parameter W=32, A=5)(
  input clk, rst,
  input [W-1:0] req,
  output reg [A-1:0] addr_reg
);

reg [W-1:0] req_pipe;
wire [A-1:0] next_addr;
wire [W-1:0] mask;

// Priority encoder logic
assign mask = req_pipe & (~req_pipe + 1);  // Isolate rightmost 1
assign next_addr = (mask[31] ? 5'd31 :
                   mask[30] ? 5'd30 :
                   mask[29] ? 5'd29 :
                   mask[28] ? 5'd28 :
                   mask[27] ? 5'd27 :
                   mask[26] ? 5'd26 :
                   mask[25] ? 5'd25 :
                   mask[24] ? 5'd24 :
                   mask[23] ? 5'd23 :
                   mask[22] ? 5'd22 :
                   mask[21] ? 5'd21 :
                   mask[20] ? 5'd20 :
                   mask[19] ? 5'd19 :
                   mask[18] ? 5'd18 :
                   mask[17] ? 5'd17 :
                   mask[16] ? 5'd16 :
                   mask[15] ? 5'd15 :
                   mask[14] ? 5'd14 :
                   mask[13] ? 5'd13 :
                   mask[12] ? 5'd12 :
                   mask[11] ? 5'd11 :
                   mask[10] ? 5'd10 :
                   mask[9]  ? 5'd9  :
                   mask[8]  ? 5'd8  :
                   mask[7]  ? 5'd7  :
                   mask[6]  ? 5'd6  :
                   mask[5]  ? 5'd5  :
                   mask[4]  ? 5'd4  :
                   mask[3]  ? 5'd3  :
                   mask[2]  ? 5'd2  :
                   mask[1]  ? 5'd1  :
                   mask[0]  ? 5'd0  : 5'd0);

always @(posedge clk) begin
  if (rst) begin
    req_pipe <= 0;
    addr_reg <= 0;
  end
  else begin
    req_pipe <= req;
    addr_reg <= next_addr;
  end
end

endmodule