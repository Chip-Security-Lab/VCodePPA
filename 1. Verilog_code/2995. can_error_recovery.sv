module can_error_recovery(
  input wire clk, rst_n,
  input wire error_detected, bus_off_state,
  input wire [7:0] tx_error_count, rx_error_count,
  output reg [1:0] error_state,
  output reg error_passive_mode, recovery_in_progress
);
  localparam ERROR_ACTIVE = 0, ERROR_PASSIVE = 1, BUS_OFF = 2;
  reg [9:0] recovery_counter;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      error_state <= ERROR_ACTIVE;
      error_passive_mode <= 0;
      recovery_in_progress <= 0;
      recovery_counter <= 0;
    end else begin
      // Error state determination
      if (tx_error_count >= 8'd255 || bus_off_state) begin
        error_state <= BUS_OFF;
        error_passive_mode <= 1;
        recovery_in_progress <= 1;
        recovery_counter <= 10'd1;
      end else if (tx_error_count >= 8'd128 || rx_error_count >= 8'd128) begin
        error_state <= ERROR_PASSIVE;
        error_passive_mode <= 1;
        recovery_in_progress <= 0;
      end else begin
        error_state <= ERROR_ACTIVE;
        error_passive_mode <= 0;
        recovery_in_progress <= 0;
      end
      
      // Bus off recovery
      if (recovery_in_progress) begin
        recovery_counter <= recovery_counter + 1;
        if (recovery_counter >= 10'd128) begin
          recovery_in_progress <= 0;
        end
      end
    end
  end
endmodule