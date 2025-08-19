//SystemVerilog
module prio_enc_latch_sync #(parameter BITS=6)(
  input clk, latch_en, rst,
  input [BITS-1:0] din,
  output reg [$clog2(BITS)-1:0] enc_addr
);
  reg [BITS-1:0] latched_data;
  
  always @(posedge clk) begin
    if(rst) begin
      latched_data <= 0;
      enc_addr <= 0;
    end
    else begin
      if(latch_en) latched_data <= din;
      
      // 优化的优先编码器逻辑 - 从高位到低位扫描
      casez(latched_data)
        {{(BITS-1){1'b?}}, 1'b1}: enc_addr <= 0;
        {{(BITS-2){1'b?}}, 1'b1, 1'b0}: enc_addr <= 1;
        {{(BITS-3){1'b?}}, 1'b1, 2'b0}: enc_addr <= 2;
        {{(BITS-4){1'b?}}, 1'b1, 3'b0}: enc_addr <= 3;
        {{(BITS-5){1'b?}}, 1'b1, 4'b0}: enc_addr <= 4;
        {{(BITS-6){1'b?}}, 1'b1, 5'b0}: enc_addr <= 5;
        default: enc_addr <= 0;
      endcase
    end
  end
endmodule