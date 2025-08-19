//SystemVerilog
module reset_sync_sync_reset #(
  parameter STAGES = 2,          // Number of synchronization stages
  parameter RESET_ACTIVE_LOW = 1 // Reset polarity configuration (1=active low, 0=active high)
)(
  input  wire clk,     // Clock input
  input  wire rst_n,   // Asynchronous reset input (active low by default)
  output wire sync_rst // Synchronized reset output (active low)
);
  
  // 优化后的同步寄存器链
  reg [STAGES:0] sync_stages;
  
  generate
    if (RESET_ACTIVE_LOW) begin : gen_active_low
      // 前向寄存器重定时：直接对输入应用预处理
      wire rst_in = 1'b1; // 默认非复位值
      
      always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
          sync_stages <= {(STAGES+1){1'b0}};
        end else begin
          // 将输入端寄存器移向数据流方向
          sync_stages <= {sync_stages[STAGES-1:0], rst_in};
        end
      end
      
      assign sync_rst = sync_stages[STAGES];
    end else begin : gen_active_high
      // 前向寄存器重定时：直接对输入应用预处理
      wire rst_in = 1'b0; // 默认非复位值
      
      always @(posedge clk or posedge rst_n) begin
        if (rst_n) begin
          sync_stages <= {(STAGES+1){1'b1}};
        end else begin
          // 将输入端寄存器移向数据流方向
          sync_stages <= {sync_stages[STAGES-1:0], rst_in};
        end
      end
      
      assign sync_rst = sync_stages[STAGES];
    end
  endgenerate
  
endmodule