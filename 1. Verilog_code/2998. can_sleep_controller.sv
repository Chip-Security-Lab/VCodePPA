module can_sleep_controller(
  input wire clk, rst_n,
  input wire can_rx, activity_timeout,
  input wire sleep_request, wake_request,
  output reg can_sleep_mode,
  output reg can_wake_event,
  output reg power_down_enable
);
  localparam ACTIVE = 0, LISTEN_ONLY = 1, SLEEP_PENDING = 2, SLEEP = 3, WAKEUP = 4;
  reg [2:0] state, next_state;
  reg [15:0] timeout_counter;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= ACTIVE;
      can_sleep_mode <= 0;
      can_wake_event <= 0;
      power_down_enable <= 0;
      timeout_counter <= 0;
    end else begin
      state <= next_state;
      
      case (state)
        ACTIVE: begin
          can_sleep_mode <= 0;
          power_down_enable <= 0;
          if (sleep_request)
            next_state <= SLEEP_PENDING;
        end
        SLEEP_PENDING: begin
          timeout_counter <= timeout_counter + 1;
          if (timeout_counter >= 16'hFFFF || activity_timeout)
            next_state <= SLEEP;
        end
        SLEEP: begin
          can_sleep_mode <= 1;
          power_down_enable <= 1;
          if (wake_request || !can_rx) // Wake on CAN activity (dominant bit)
            next_state <= WAKEUP;
        end
        WAKEUP: begin
          can_wake_event <= 1;
          can_sleep_mode <= 0;
          power_down_enable <= 0;
          next_state <= ACTIVE;
        end
      endcase
    end
  end
endmodule