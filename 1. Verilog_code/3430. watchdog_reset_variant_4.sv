//SystemVerilog
module watchdog_reset #(
  parameter TIMEOUT = 1024
) (
  input  wire clk,
  input  wire watchdog_kick,
  input  wire rst_n,
  output reg  watchdog_rst
);
  // Constants and width calculation
  localparam COUNTER_WIDTH = $clog2(TIMEOUT);
  
  // Signal declarations - optimized for better area and timing
  reg [COUNTER_WIDTH-1:0] counter_r;
  wire counter_reset;
  wire counter_max;
  wire counter_increment;
  
  // Optimized kick detection - single stage for reduced latency
  reg kick_detected_r;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      kick_detected_r <= 1'b0;
    end else begin
      kick_detected_r <= watchdog_kick;
    end
  end
  
  // Efficient comparison logic for timeout detection
  // Using equality comparison instead of range checking
  assign counter_max = (counter_r == (TIMEOUT - 1));
  
  // Counter control signals with prioritized logic
  assign counter_reset = kick_detected_r;
  assign counter_increment = ~counter_max & ~counter_reset;
  
  // Combined counter update with prioritized reset
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      counter_r <= {COUNTER_WIDTH{1'b0}};
    end else if (counter_reset) begin
      counter_r <= {COUNTER_WIDTH{1'b0}};
    end else if (counter_increment) begin
      counter_r <= counter_r + 1'b1;
    end
  end
  
  // Direct output generation logic
  // Using registered counter_max for better timing
  reg counter_at_max_r;
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      counter_at_max_r <= 1'b0;
      watchdog_rst <= 1'b0;
    end else begin
      counter_at_max_r <= counter_max;
      watchdog_rst <= counter_at_max_r;
    end
  end
  
endmodule