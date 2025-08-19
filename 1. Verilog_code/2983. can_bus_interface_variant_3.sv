//SystemVerilog
//IEEE 1364-2005 Verilog
module can_bus_interface #(
  parameter CLK_FREQ_MHZ = 40,
  parameter CAN_BITRATE_KBPS = 1000
)(
  input wire clk, rst_n,
  input wire tx_data_bit,
  output reg rx_data_bit,
  input wire can_rx,
  output reg can_tx,
  output reg bit_sample_point
);
  localparam DIVIDER = (CLK_FREQ_MHZ * 1000) / CAN_BITRATE_KBPS;
  localparam SAMPLE_POINT = (DIVIDER * 3) >> 2;
  
  reg [15:0] counter;
  reg sample_enable;
  
  // 优化比较逻辑，使用范围检查代替相等比较
  wire counter_at_top = (counter >= DIVIDER-1);
  wire counter_at_sample = (counter == SAMPLE_POINT);
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      counter <= 16'h0;
      bit_sample_point <= 1'b0;
      can_tx <= 1'b1; // Recessive state
      sample_enable <= 1'b0;
      rx_data_bit <= 1'b1;
    end else begin
      // 重新排序比较操作，使用触发式逻辑
      if (counter_at_top) begin
        counter <= 16'h0;
        sample_enable <= 1'b1;
      end else begin
        counter <= counter + 16'h1;
        sample_enable <= 1'b0;
      end
      
      // 使用触发式采样，减少逻辑路径
      bit_sample_point <= counter_at_sample;
      
      // 合并TX逻辑，减少条件检查
      can_tx <= sample_enable ? tx_data_bit : can_tx;
      
      // 使用边沿触发式采样
      if (counter_at_sample)
        rx_data_bit <= can_rx;
    end
  end
endmodule