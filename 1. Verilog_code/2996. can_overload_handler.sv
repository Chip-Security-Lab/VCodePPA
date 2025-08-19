module can_overload_handler(
  input wire clk, rst_n,
  input wire can_rx, bit_timing,
  input wire frame_end, inter_frame_space,
  output reg overload_detected,
  output reg can_tx_overload
);
  reg [2:0] state;
  reg [3:0] bit_counter;
  
  localparam IDLE = 0, DETECT = 1, FLAG = 2, DELIMITER = 3;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= IDLE;
      overload_detected <= 0;
      can_tx_overload <= 0;
      bit_counter <= 0;
    end else if (bit_timing) begin
      case (state)
        IDLE: begin
          if (frame_end)
            state <= DETECT;
        end
        DETECT: begin
          // Detect overload condition (dominant bit in IFS)
          if (inter_frame_space && !can_rx) begin
            state <= FLAG;
            overload_detected <= 1;
            bit_counter <= 0;
          end
        end
        FLAG: begin
          // Send 6 dominant bits
          can_tx_overload <= 1;
          bit_counter <= bit_counter + 1;
          if (bit_counter >= 5)
            state <= DELIMITER;
        end
        DELIMITER: begin
          // Send 8 recessive bits
          can_tx_overload <= 0;
          bit_counter <= bit_counter + 1;
          if (bit_counter >= 7) begin
            state <= IDLE;
            overload_detected <= 0;
          end
        end
      endcase
    end
  end
endmodule