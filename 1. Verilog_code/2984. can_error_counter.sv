module can_error_counter(
  input wire clk, rst_n,
  input wire bit_error, stuff_error, form_error, crc_error, ack_error,
  input wire tx_success, rx_success,
  output reg [7:0] tx_err_count,
  output reg [7:0] rx_err_count,
  output reg bus_off
);
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tx_err_count <= 0;
      rx_err_count <= 0;
      bus_off <= 0;
    end else begin
      if (tx_success) begin
        tx_err_count <= (tx_err_count > 0) ? tx_err_count - 1 : 0;
      end else if (bit_error || stuff_error || form_error || crc_error || ack_error) begin
        if (tx_err_count < 255) tx_err_count <= tx_err_count + 8;
      end
      
      if (rx_success) begin
        rx_err_count <= (rx_err_count > 0) ? rx_err_count - 1 : 0;
      end
      
      bus_off <= (tx_err_count >= 255);
    end
  end
endmodule