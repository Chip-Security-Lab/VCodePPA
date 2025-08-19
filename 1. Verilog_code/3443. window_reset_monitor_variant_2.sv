//SystemVerilog
module window_reset_monitor #(
  parameter MIN_WINDOW = 4,
  parameter MAX_WINDOW = 12
) (
  input wire clk,
  input wire reset_pulse,
  output reg valid_reset
);
  reg [$clog2(MAX_WINDOW):0] window_counter;
  reg reset_active;
  
  // Manchester carry chain adder signals
  wire [$clog2(MAX_WINDOW):0] sum;
  wire [$clog2(MAX_WINDOW):0] p; // Propagate
  wire [$clog2(MAX_WINDOW):0] g; // Generate
  wire [$clog2(MAX_WINDOW)+1:0] c; // Carry signals
  
  // Generate and propagate signals
  assign p = window_counter;
  assign g = 0;
  assign c[0] = 1'b1; // Carry-in for increment operation
  
  // Manchester carry chain logic
  genvar i;
  generate
    for (i = 0; i <= $clog2(MAX_WINDOW); i = i + 1) begin : carry_chain
      assign c[i+1] = g[i] | (p[i] & c[i]);
      assign sum[i] = p[i] ^ c[i];
    end
  endgenerate
  
  // State encoding for case statement
  localparam IDLE = 2'b00;
  localparam COUNTING = 2'b01;
  localparam CHECK_WINDOW = 2'b10;
  
  // State variable derived from reset_pulse and reset_active
  reg [1:0] state;
  
  always @(*) begin
    case ({reset_pulse, reset_active})
      2'b10: state = IDLE;      // reset_pulse=1, reset_active=0
      2'b11: state = COUNTING;  // reset_pulse=1, reset_active=1
      2'b01: state = CHECK_WINDOW; // reset_pulse=0, reset_active=1
      2'b00: state = IDLE;      // reset_pulse=0, reset_active=0
    endcase
  end
  
  always @(posedge clk) begin
    case (state)
      IDLE: begin
        if (reset_pulse) begin
          reset_active <= 1'b1;
          window_counter <= 0;
          valid_reset <= 1'b0;
        end
      end
      
      COUNTING: begin
        window_counter <= sum; // Use Manchester carry chain adder result
        if (!reset_pulse) begin
          reset_active <= 1'b0;
        end
      end
      
      CHECK_WINDOW: begin
        valid_reset <= (window_counter >= MIN_WINDOW) && 
                       (window_counter <= MAX_WINDOW);
        reset_active <= 1'b0;
      end
      
      default: begin
        reset_active <= 1'b0;
        valid_reset <= 1'b0;
      end
    endcase
  end
endmodule