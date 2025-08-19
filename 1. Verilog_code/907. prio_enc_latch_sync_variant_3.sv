//SystemVerilog
module prio_enc_latch_sync #(parameter BITS=6)(
  input clk, latch_en, rst,
  input [BITS-1:0] din,
  output reg [$clog2(BITS)-1:0] enc_addr
);

reg [BITS-1:0] latched_data;
reg [$clog2(BITS)-1:0] enc_addr_comb;

// 合并所有always块
always @(posedge clk or posedge rst) begin
  if(rst) begin
    latched_data <= 0;
    enc_addr <= 0;
  end
  else begin
    // 数据锁存逻辑
    if(latch_en) latched_data <= din;
    
    // 优先编码器逻辑
    enc_addr_comb = 0;
    for(int i=BITS-1; i>=0; i=i-1) begin
      if(latched_data[i]) enc_addr_comb = i[$clog2(BITS)-1:0];
    end
    
    // 更新输出
    enc_addr <= enc_addr_comb;
  end
end

endmodule