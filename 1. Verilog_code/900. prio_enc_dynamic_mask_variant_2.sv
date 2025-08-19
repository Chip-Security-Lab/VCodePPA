//SystemVerilog
// SystemVerilog
// IEEE 1364-2005
module prio_enc_dynamic_mask #(parameter W=8)(
  input clk,
  input [W-1:0] mask,
  input [W-1:0] req,
  output reg [$clog2(W)-1:0] index
);
  
  reg [W-1:0] mask_reg, req_reg;
  wire [W-1:0] masked_req;
  
  // 合并所有相同触发条件(posedge clk)的always块
  always @(posedge clk) begin
    // 寄存输入信号
    mask_reg <= mask;
    req_reg <= req;
    // 计算优先编码并更新输出
    index <= find_first(req_reg & mask_reg);
  end
  
  // 优先编码函数
  function [$clog2(W)-1:0] find_first;
    input [W-1:0] vec;
    integer j;
    begin
      find_first = 0;
      for(j=0; j<W; j=j+1)
        if(vec[j]) find_first = j[$clog2(W)-1:0];
    end
  endfunction
  
endmodule