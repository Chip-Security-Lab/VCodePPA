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
  reg [15:0] counter;
  reg sample_enable;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      counter <= 0;
      bit_sample_point <= 0;
      can_tx <= 1; // Recessive state
    end else begin
      counter <= (counter >= DIVIDER-1) ? 0 : counter + 1;
      bit_sample_point <= (counter == (DIVIDER*3/4));
      sample_enable <= (counter == 0);
      if (sample_enable)
        can_tx <= tx_data_bit;
      if (bit_sample_point)
        rx_data_bit <= can_rx;
    end
  end
endmodule