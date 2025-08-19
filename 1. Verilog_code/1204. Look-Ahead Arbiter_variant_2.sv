//SystemVerilog
//IEEE 1364-2005
module look_ahead_arbiter #(parameter REQS=4) (
  input wire clk, rst_n,
  input wire [REQS-1:0] req,
  input wire [REQS-1:0] predicted_req,
  output reg [REQS-1:0] grant
);
  reg [REQS-1:0] next_req;
  reg [1:0] current_priority;
  wire [1:0] priority_value;
  wire [1:0] complement_priority;
  reg [1:0] masked_priority;
  
  // 使用补码加法实现减法
  // 计算被减数的补码 (取反加一)
  assign complement_priority = ~current_priority + 2'b01;
  
  // 优化的优先级编码函数
  function [1:0] priority_encoder;
    input [REQS-1:0] request_vector;
    begin
      if (request_vector[0]) begin
        priority_encoder = 2'd0;
      end else if (request_vector[1]) begin
        priority_encoder = 2'd1;
      end else if (request_vector[2]) begin
        priority_encoder = 2'd2;
      end else begin
        priority_encoder = 2'd3;
      end
    end
  endfunction
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      grant <= {REQS{1'b0}};
      current_priority <= 2'b0;
      next_req <= {REQS{1'b0}};
    end else begin
      next_req <= predicted_req;
      grant <= {REQS{1'b0}};
      
      if (req[current_priority]) begin
        // Grant to current priority if it has a request
        grant[current_priority] <= 1'b1;
      end else if (|req) begin
        // 使用补码加法来计算掩码优先级
        // 使用一个寄存器来存储计算结果
        reg [REQS-1:0] masked_req;
        masked_req = req;
        masked_req[current_priority] = 1'b0;
        
        // Use if-else structure instead of casez
        if (masked_req[3]) begin
          grant[3] <= 1'b1;
        end else if (masked_req[2]) begin
          grant[2] <= 1'b1;
        end else if (masked_req[1]) begin
          grant[1] <= 1'b1;
        end else if (masked_req[0]) begin
          grant[0] <= 1'b1;
        end else begin
          grant <= {REQS{1'b0}};
        end
      end
      
      // Look ahead for next priority using function with complement addition
      if (|next_req) begin
        // 使用补码加法计算新的优先级
        masked_priority = priority_encoder(next_req);
        current_priority <= masked_priority + complement_priority + 2'b00;
      end
    end
  end
endmodule