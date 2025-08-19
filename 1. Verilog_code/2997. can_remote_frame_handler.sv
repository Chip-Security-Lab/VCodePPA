module can_remote_frame_handler(
  input wire clk, rst_n,
  input wire rx_rtr, rx_id_valid,
  input wire [10:0] rx_id,
  output reg [10:0] tx_request_id,
  output reg tx_data_ready, tx_request
);
  reg [10:0] response_id [0:3];
  reg [3:0] response_mask;
  
  integer i;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      tx_data_ready <= 0;
      tx_request <= 0;
      response_mask <= 4'b0101; // Example: respond to some RTRs
      
      // IDs that we'll respond to with data
      response_id[0] <= 11'h100;
      response_id[1] <= 11'h200;
      response_id[2] <= 11'h300;
      response_id[3] <= 11'h400;
    end else begin
      tx_request <= 0;
      
      if (rx_id_valid && rx_rtr) begin
        // Check if received RTR ID matches any of our response IDs
        for (i = 0; i < 4; i = i + 1) begin
          if (response_mask[i] && (rx_id == response_id[i])) begin
            tx_request_id <= rx_id;
            tx_data_ready <= 1;
            tx_request <= 1;
          end
        end
      end
    end
  end
endmodule