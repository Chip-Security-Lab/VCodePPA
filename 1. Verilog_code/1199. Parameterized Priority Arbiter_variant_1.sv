//SystemVerilog
module param_priority_arbiter #(
  parameter REQ_CNT = 8,
  parameter PRIO_WIDTH = 3
)(
  input clk, reset,
  input [REQ_CNT-1:0] requests,
  input [PRIO_WIDTH-1:0] priorities [REQ_CNT-1:0],
  output reg [REQ_CNT-1:0] grants
);
  // IEEE 1364-2005 Verilog standard compliant
  
  // Optimized variables
  integer i;
  reg [PRIO_WIDTH-1:0] highest_prio;
  reg [3:0] selected;
  reg [3:0] selected_reg;
  reg req_valid;
  
  // Pipeline register to improve timing
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      selected_reg <= 0;
      req_valid <= 0;
    end
    else begin
      selected_reg <= selected;
      req_valid <= |requests;
    end
  end
  
  // Optimized priority comparison logic with multi-level conditions
  always @(*) begin
    highest_prio = 0;
    selected = 0;
    
    for (i = REQ_CNT-1; i >= 0; i = i - 1) begin
      // Level 1: Check if request is valid
      if (requests[i]) begin
        // Level 2: Check if priority is higher
        if (priorities[i] > highest_prio) begin
          highest_prio = priorities[i];
          selected = i;
        end
        // Level 3: If same priority, use position as tie-breaker
        else if (priorities[i] == highest_prio) begin
          // Level 4: Select the lower index if same priority
          if (i < selected) begin
            selected = i;
          end
        end
      end
    end
  end
  
  // Grant generation logic with simplified structure
  always @(posedge clk or posedge reset) begin
    if (reset) begin
      grants <= 0;
    end
    else begin
      // Default assignment
      grants <= 0;
      
      // Conditional grant generation
      if (req_valid) begin
        grants[selected_reg] <= 1'b1;
      end
    end
  end
endmodule