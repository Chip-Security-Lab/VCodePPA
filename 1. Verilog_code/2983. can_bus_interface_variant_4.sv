//SystemVerilog
//IEEE 1364-2005
module can_bus_interface #(
  parameter CLK_FREQ_MHZ = 40,
  parameter CAN_BITRATE_KBPS = 1000
)(
  input wire clk, rst_n,
  input wire tx_data_bit,
  output wire rx_data_bit,
  input wire can_rx,
  output wire can_tx,
  output wire bit_sample_point
);
  localparam DIVIDER = (CLK_FREQ_MHZ * 1000) / CAN_BITRATE_KBPS;
  
  wire [15:0] bit_counter;
  wire sample_enable;
  
  can_bit_timing_controller #(
    .DIVIDER(DIVIDER)
  ) bit_timing_ctrl (
    .clk(clk),
    .rst_n(rst_n),
    .counter(bit_counter),
    .bit_sample_point(bit_sample_point),
    .sample_enable(sample_enable)
  );
  
  can_rx_controller rx_ctrl (
    .clk(clk),
    .rst_n(rst_n),
    .can_rx(can_rx),
    .bit_sample_point(bit_sample_point),
    .rx_data_bit(rx_data_bit)
  );
  
  can_tx_controller tx_ctrl (
    .clk(clk),
    .rst_n(rst_n),
    .tx_data_bit(tx_data_bit),
    .sample_enable(sample_enable),
    .can_tx(can_tx)
  );
  
endmodule

module can_bit_timing_controller #(
  parameter DIVIDER = 40000
)(
  input wire clk, rst_n,
  output reg [15:0] counter,
  output reg bit_sample_point,
  output reg sample_enable
);
  
  reg [15:0] next_counter;
  reg next_bit_sample_point;
  reg next_sample_enable;
  
  always @(*) begin
    next_counter = (counter >= DIVIDER-1) ? 16'b0 : counter + 16'b1;
    next_bit_sample_point = (next_counter == (DIVIDER*3/4));
    next_sample_enable = (next_counter == 16'b0);
  end
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      counter <= 16'b0;
      bit_sample_point <= 1'b0;
      sample_enable <= 1'b0;
    end else begin
      counter <= next_counter;
      bit_sample_point <= next_bit_sample_point;
      sample_enable <= next_sample_enable;
    end
  end
  
endmodule

module can_rx_controller (
  input wire clk, rst_n,
  input wire can_rx,
  input wire bit_sample_point,
  output reg rx_data_bit
);
  
  reg sampled_can_rx;
  
  // 前移寄存器，先采样输入信号
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      sampled_can_rx <= 1'b0;
    end else begin
      sampled_can_rx <= can_rx;
    end
  end
  
  // 在采样点进行处理
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rx_data_bit <= 1'b0;
    end else if (bit_sample_point) begin
      rx_data_bit <= sampled_can_rx;
    end
  end
  
endmodule

module can_tx_controller (
  input wire clk, rst_n,
  input wire tx_data_bit,
  input wire sample_enable,
  output reg can_tx
);
  
  reg latched_tx_data_bit;
  
  // 前移寄存器，先锁存输入数据位
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      latched_tx_data_bit <= 1'b0;
    end else begin
      latched_tx_data_bit <= tx_data_bit;
    end
  end
  
  // 在使能时输出锁存的数据位
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      can_tx <= 1'b1; // Recessive state
    end else if (sample_enable) begin
      can_tx <= latched_tx_data_bit;
    end
  end
  
endmodule