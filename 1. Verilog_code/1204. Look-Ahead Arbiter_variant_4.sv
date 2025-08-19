//SystemVerilog
module look_ahead_arbiter #(parameter REQS=4) (
  input wire clk, rst_n,
  input wire [REQS-1:0] req,
  input wire [REQS-1:0] predicted_req,
  output reg [REQS-1:0] grant
);
  reg [REQS-1:0] next_req;
  reg [1:0] current_priority;
  
  // 扁平化的优先级逻辑
  wire [1:0] next_priority;
  
  // 使用扁平化的if-else结构
  wire next_req0_has_priority = next_req[0];
  wire next_req1_has_priority = !next_req[0] && next_req[1];
  wire next_req2_has_priority = !next_req[0] && !next_req[1] && next_req[2];
  wire next_req3_has_priority = !next_req[0] && !next_req[1] && !next_req[2] && next_req[3];
  
  assign next_priority = next_req0_has_priority ? 2'd0 :
                         next_req1_has_priority ? 2'd1 :
                         next_req2_has_priority ? 2'd2 : 2'd3;
  
  // 扁平化的授权逻辑
  wire [REQS-1:0] potential_grant;
  
  // 使用逻辑与(&&)组合条件的扁平化结构
  wire req0_is_priority = req[0] && current_priority == 2'd0;
  wire req0_is_lowest_active = req[0] && |req && !(|req & (4'b1110 << current_priority));
  
  wire req1_is_priority = req[1] && current_priority == 2'd1;
  wire req1_is_lowest_active = req[1] && |req && !(|req & (4'b1100 << current_priority)) && !req[0];
  
  wire req2_is_priority = req[2] && current_priority == 2'd2;
  wire req2_is_lowest_active = req[2] && |req && !(|req & (4'b1000 << current_priority)) && !(|req[1:0]);
  
  wire req3_is_priority = req[3] && current_priority == 2'd3;
  wire req3_is_lowest_active = req[3] && |req && !(|req[2:0]);
  
  assign potential_grant[0] = req0_is_priority || req0_is_lowest_active;
  assign potential_grant[1] = req1_is_priority || req1_is_lowest_active;
  assign potential_grant[2] = req2_is_priority || req2_is_lowest_active;
  assign potential_grant[3] = req3_is_priority || req3_is_lowest_active;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      grant <= {REQS{1'b0}};
      current_priority <= 2'd0;
      next_req <= {REQS{1'b0}};
    end else begin
      next_req <= predicted_req;
      grant <= potential_grant;
      
      // 基于预测请求更新优先级
      if (|next_req) begin
        current_priority <= next_priority;
      end
    end
  end
endmodule