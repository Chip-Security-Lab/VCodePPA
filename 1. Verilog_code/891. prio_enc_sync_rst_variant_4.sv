//SystemVerilog
// IEEE 1364-2005 SystemVerilog
module prio_enc_sync_rst #(parameter WIDTH=8, ADDR=3)(
  input clk, rst_n,
  input [WIDTH-1:0] req_in,
  output reg [ADDR-1:0] addr_out
);

reg [WIDTH-1:0] req_mask;
wire [ADDR-1:0] temp_addr;
reg [WIDTH-1:0] sum_req;

// 将组合逻辑从寄存器中移出，转为连续赋值
assign temp_addr[0] = sum_req[1] | sum_req[3] | sum_req[5] | sum_req[7];
assign temp_addr[1] = sum_req[2] | sum_req[3] | sum_req[6] | sum_req[7];
assign temp_addr[2] = sum_req[4] | sum_req[5] | sum_req[6] | sum_req[7];

always @(posedge clk) begin
  if (!rst_n) begin
    addr_out <= 0;
    req_mask <= 0;
    sum_req <= 0;
  end
  else begin
    // 优化数据流
    req_mask <= req_in & {WIDTH{1'b1}};
    sum_req <= req_mask;
    // 重定时：将寄存器移至组合逻辑之后
    addr_out <= temp_addr;
  end
end

endmodule