//SystemVerilog
module can_receiver(
  input clk, reset_n, can_rx,
  output reg rx_active, rx_done, frame_error,
  output reg [10:0] identifier,
  output reg [7:0] data_out [0:7],
  output reg [3:0] data_length
);
  localparam IDLE=0, SOF=1, ID=2, RTR=3, CONTROL=4, DATA=5, CRC=6, ACK=7, EOF=8;
  reg [3:0] state;
  reg [7:0] bit_count, data_count;
  reg [14:0] crc, crc_received;
  
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      state <= IDLE;
      rx_active <= 0;
      rx_done <= 0;
    end else if (state == IDLE && !can_rx) begin
      state <= SOF;
      rx_active <= 1;
    end
    // Additional state logic for CAN frame reception would be flat if-else statements here
    // using the && operator to combine conditions, instead of nested case/if structures
  end
endmodule