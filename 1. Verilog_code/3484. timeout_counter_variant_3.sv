//SystemVerilog
module timeout_counter #(
  parameter TIMEOUT = 100
)(
  input wire clk, 
  input wire manual_rst, 
  input wire enable,
  output reg timeout_flag
);
  
  // Optimal bit width calculation
  localparam COUNT_WIDTH = $clog2(TIMEOUT);
  reg [COUNT_WIDTH-1:0] counter;
  
  // Pre-calculate the terminal count value for better timing
  localparam TERMINAL_COUNT = TIMEOUT - 1;
  
  // Control signals for case statement
  reg [1:0] ctrl;
  
  always @(posedge clk) begin
    // Create control variable for case statement
    ctrl = {manual_rst, enable};
    
    case (ctrl)
      2'b10, 2'b11: begin // manual_rst is active (regardless of enable)
        counter <= {COUNT_WIDTH{1'b0}};
        timeout_flag <= 1'b0;
      end
      
      2'b01: begin // enable active, manual_rst inactive
        if (counter == TERMINAL_COUNT) begin
          counter <= {COUNT_WIDTH{1'b0}};
          timeout_flag <= 1'b1;
        end 
        else begin
          counter <= counter + 1'b1;
          timeout_flag <= 1'b0;
        end
      end
      
      2'b00: begin // both inactive, hold values
        counter <= counter;
        timeout_flag <= timeout_flag;
      end
      
      default: begin // catch any illegal states
        counter <= counter;
        timeout_flag <= timeout_flag;
      end
    endcase
  end
  
endmodule