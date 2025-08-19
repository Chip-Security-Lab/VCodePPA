//SystemVerilog
module binary_encoded_arbiter #(parameter WIDTH=4) (
  input clk, reset_n,
  input [WIDTH-1:0] req_i,
  output reg [$clog2(WIDTH)-1:0] sel_o,
  output reg valid_o
);
  // Stage 1 registers
  reg [WIDTH-1:0] req_stage1;
  reg valid_stage1;
  
  // Stage 2 registers
  reg [$clog2(WIDTH)-1:0] sel_stage2;
  reg valid_stage2;
  
  // Internal signals for stage 1
  wire [WIDTH-1:0] priority_mask;
  wire [WIDTH-1:0] isolated_req;
  wire [$clog2(WIDTH)-1:0] encoded_sel;
  wire has_req;
  
  // Request detection logic
  assign has_req = |req_i;
  
  // Create priority mask (all bits to the right of MSB '1' are set)
  genvar j;
  generate
    for (j = 0; j < WIDTH; j = j + 1) begin : gen_priority
      if (j == 0) begin
        assign priority_mask[j] = 1'b0;
      end else begin
        assign priority_mask[j] = |req_i[j-1:0];
      end
    end
  endgenerate
  
  // Isolate the highest priority request (rightmost '1')
  assign isolated_req = req_i & ~priority_mask;
  
  // Binary encoder for isolated request
  reg [$clog2(WIDTH)-1:0] temp_sel;
  integer i;
  
  always @(*) begin
    temp_sel = {$clog2(WIDTH){1'b0}};
    for (i = 0; i < WIDTH; i = i + 1) begin
      if (isolated_req[i]) begin
        temp_sel = i[$clog2(WIDTH)-1:0];
      end
    end
  end
  
  assign encoded_sel = temp_sel;
  
  // Combined reset and clock logic for all registers
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      // Reset all registers
      req_stage1 <= {WIDTH{1'b0}};
      valid_stage1 <= 1'b0;
      sel_stage2 <= {$clog2(WIDTH){1'b0}};
      valid_stage2 <= 1'b0;
      sel_o <= {$clog2(WIDTH){1'b0}};
      valid_o <= 1'b0;
    end else begin
      // Normal operation - pipeline stages
      // Stage 1
      req_stage1 <= isolated_req;
      valid_stage1 <= has_req;
      
      // Stage 2
      sel_stage2 <= encoded_sel;
      valid_stage2 <= valid_stage1;
      
      // Output stage
      sel_o <= sel_stage2;
      valid_o <= valid_stage2;
    end
  end
endmodule