//SystemVerilog
module timeout_counter #(parameter TIMEOUT = 100)(
  input wire clk, 
  input wire manual_rst, 
  input wire enable,
  output wire timeout_flag
);
  
  // Internal signals
  wire enable_r;
  wire manual_rst_r;
  wire counter_will_timeout;
  wire [$clog2(TIMEOUT):0] counter_value;
  
  // Input register submodule instantiation
  input_register u_input_register (
    .clk(clk),
    .enable(enable),
    .manual_rst(manual_rst),
    .enable_r(enable_r),
    .manual_rst_r(manual_rst_r)
  );
  
  // Timeout condition detector submodule instantiation
  timeout_detector #(
    .TIMEOUT(TIMEOUT)
  ) u_timeout_detector (
    .clk(clk),
    .enable_r(enable_r),
    .counter_value(counter_value),
    .counter_will_timeout(counter_will_timeout)
  );
  
  // Counter control submodule instantiation
  counter_control #(
    .TIMEOUT(TIMEOUT)
  ) u_counter_control (
    .clk(clk),
    .manual_rst_r(manual_rst_r),
    .enable_r(enable_r),
    .counter_will_timeout(counter_will_timeout),
    .counter_value(counter_value),
    .timeout_flag(timeout_flag)
  );
  
endmodule

// Input register module to improve timing path
module input_register (
  input wire clk,
  input wire enable,
  input wire manual_rst,
  output reg enable_r,
  output reg manual_rst_r
);
  
  // Register the enable input
  always @(posedge clk) begin
    enable_r <= enable;
  end
  
  // Register the manual reset input
  always @(posedge clk) begin
    manual_rst_r <= manual_rst;
  end
  
endmodule

// Timeout detection module 
module timeout_detector #(parameter TIMEOUT = 100)(
  input wire clk,
  input wire enable_r,
  input wire [$clog2(TIMEOUT):0] counter_value,
  output reg counter_will_timeout
);

  // Pre-compute timeout condition to reduce critical path
  always @(posedge clk) begin
    counter_will_timeout <= (counter_value == TIMEOUT - 2) && enable_r;
  end
  
endmodule

// Counter control module
module counter_control #(parameter TIMEOUT = 100)(
  input wire clk,
  input wire manual_rst_r,
  input wire enable_r,
  input wire counter_will_timeout,
  output reg [$clog2(TIMEOUT):0] counter_value,
  output reg timeout_flag
);
  
  // Counter value update logic
  always @(posedge clk) begin
    if (manual_rst_r) begin
      counter_value <= 0;
    end else if (enable_r) begin
      if (counter_will_timeout) begin
        counter_value <= 0;
      end else begin
        counter_value <= counter_value + 1;
      end
    end
  end
  
  // Timeout flag control logic
  always @(posedge clk) begin
    if (manual_rst_r) begin
      timeout_flag <= 0;
    end else if (enable_r) begin
      if (counter_will_timeout) begin
        timeout_flag <= 1;
      end else begin
        timeout_flag <= 0;
      end
    end
  end
  
endmodule