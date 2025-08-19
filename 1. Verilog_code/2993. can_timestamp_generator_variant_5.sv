//SystemVerilog
module can_timestamp_generator(
  input wire clk, rst_n,
  input wire can_rx_edge, can_frame_start, can_frame_end,
  output reg [31:0] current_timestamp,
  output reg [31:0] frame_timestamp,
  output reg timestamp_valid
);
  reg [15:0] prescaler_count;
  reg prescaler_overflow;
  reg frame_end_reg;
  localparam PRESCALER = 1000; // For microsecond resolution
  
  // Manchester carry chain signals
  wire [31:0] propagate;
  wire [31:0] generate_bit;
  wire [32:0] carry;
  wire [31:0] sum;
  
  // Pre-calculate the prescaler comparison result to reduce critical path
  always @(*) begin
    prescaler_overflow = (prescaler_count >= (PRESCALER - 1));
  end
  
  // Manchester carry chain adder implementation
  assign propagate = current_timestamp;
  assign generate_bit = 32'h00000000;
  assign carry[0] = 1'b1; // Add 1 to current_timestamp
  
  // Generate carry chain
  genvar i;
  generate
    for (i = 0; i < 32; i = i + 1) begin : manchester_carry_chain
      assign carry[i+1] = generate_bit[i] | (propagate[i] & carry[i]);
    end
  endgenerate
  
  // Calculate sum
  assign sum = propagate ^ carry[31:0];
  
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      current_timestamp <= 0;
      frame_timestamp <= 0;
      timestamp_valid <= 0;
      prescaler_count <= 0;
      frame_end_reg <= 0;
    end else begin
      // Default assignment to reduce logic depth
      timestamp_valid <= 0;
      frame_end_reg <= can_frame_end;
      
      // Prescaler counter logic
      if (prescaler_overflow) begin
        prescaler_count <= 0;
        current_timestamp <= sum; // Use Manchester carry chain adder result
      end else begin
        prescaler_count <= prescaler_count + 1;
      end
      
      // Capture timestamp at frame start
      if (can_frame_start) begin
        frame_timestamp <= current_timestamp;
      end
      
      // Generate valid signal on frame end
      if (frame_end_reg) begin
        timestamp_valid <= 1;
      end
    end
  end
endmodule