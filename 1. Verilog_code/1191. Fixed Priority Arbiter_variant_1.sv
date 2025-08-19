//SystemVerilog
module fixed_priority_arbiter #(parameter N=4) (
  input wire clk, rst_n,
  input wire [N-1:0] req,
  output reg [N-1:0] grant
);
  // 优化后的逻辑实现
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      grant <= {N{1'b0}};
    end
    else begin
      // 优先级编码逻辑 - 只授权最高优先级的请求
      grant <= {N{1'b0}}; // 默认全部不授权
      
      // 从最高优先级(0)到最低优先级(N-1)扫描
      // 使用casez实现优先级编码器，提高效率
      casez (req)
        {N{1'b?}}: begin // 通配模式确保始终有匹配
          // 优先编码逻辑 - 进行独热码转换
          if (req[0]) grant[0] <= 1'b1;
          else if (req[1]) grant[1] <= 1'b1;
          else if (req[2]) grant[2] <= 1'b1;
          else if (req[3]) grant[3] <= 1'b1;
          // 如果N>4，这里会需要更多条件
        end
      endcase
    end
  end
endmodule