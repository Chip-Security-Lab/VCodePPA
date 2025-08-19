//SystemVerilog
module reset_sequencer (
  input wire clk,
  input wire global_rst,
  output reg rst_domain1,
  output reg rst_domain2,
  output reg rst_domain3
);
  reg [3:0] seq_counter;
  
  // 使用简单的递增逻辑代替先行进位加法器
  wire [3:0] next_counter;
  assign next_counter = (seq_counter == 4'd15) ? seq_counter : seq_counter + 4'd1;
  
  always @(posedge clk or posedge global_rst) begin
    if (global_rst) begin
      seq_counter <= 4'd0;
      {rst_domain1, rst_domain2, rst_domain3} <= 3'b111;
    end else begin
      seq_counter <= next_counter;
      
      // 使用优化的比较逻辑
      // 使用范围检查代替单独的比较
      // 将seq_counter[3:2]与常量比较，减少比较逻辑
      case (seq_counter[3:2])
        2'b00: {rst_domain1, rst_domain2, rst_domain3} <= 3'b111;
        2'b01: begin
          rst_domain1 <= 1'b0;
          rst_domain2 <= 1'b1;
          rst_domain3 <= 1'b1;
        end
        2'b10: begin
          rst_domain1 <= 1'b0;
          rst_domain2 <= 1'b0;
          rst_domain3 <= 1'b1;
        end
        2'b11: begin
          rst_domain1 <= 1'b0;
          rst_domain2 <= 1'b0;
          rst_domain3 <= (seq_counter[1:0] < 2'b11) ? 1'b1 : 1'b0;
        end
      endcase
    end
  end
endmodule