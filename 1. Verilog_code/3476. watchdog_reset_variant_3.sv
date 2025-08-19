//SystemVerilog
module watchdog_reset #(parameter TIMEOUT = 1000)(
  input clk, ext_rst_n, watchdog_clear,
  output reg watchdog_rst
);
  reg [$clog2(TIMEOUT)-1:0] timer;
  reg watchdog_clear_r;
  wire timer_reset;
  wire [$clog2(TIMEOUT)-1:0] next_timer;
  wire next_watchdog_rst;
  
  // Move register forward - capture input at clock edge
  always @(posedge clk or negedge ext_rst_n) begin
    if (!ext_rst_n) begin
      watchdog_clear_r <= 1'b0;
    end else begin
      watchdog_clear_r <= watchdog_clear;
    end
  end
  
  // Combinational logic with explicit multiplexer structure
  assign timer_reset = watchdog_clear_r | ~ext_rst_n;
  
  // Explicit multiplexer for next_timer
  reg [$clog2(TIMEOUT)-1:0] timer_plus_one;
  always @(*) begin
    timer_plus_one = timer + 1'b1;
  end
  
  assign next_timer = timer_reset ? {$clog2(TIMEOUT){1'b0}} : 
                      (timer < TIMEOUT - 1) ? timer_plus_one : 
                      timer;
  
  // Explicit multiplexer for next_watchdog_rst
  wire timeout_reached;
  assign timeout_reached = (timer >= TIMEOUT - 1);
  
  assign next_watchdog_rst = timer_reset ? 1'b0 :
                             timeout_reached ? 1'b1 : 
                             watchdog_rst;
  
  // State registers now located after combinational logic
  always @(posedge clk or negedge ext_rst_n) begin
    if (!ext_rst_n) begin
      timer <= {$clog2(TIMEOUT){1'b0}};
      watchdog_rst <= 1'b0;
    end else begin
      timer <= next_timer;
      watchdog_rst <= next_watchdog_rst;
    end
  end
endmodule