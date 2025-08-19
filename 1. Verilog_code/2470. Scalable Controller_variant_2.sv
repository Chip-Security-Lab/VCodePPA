//SystemVerilog IEEE 1364-2005
module scalable_intr_ctrl #(
  parameter SOURCES = 32,
  parameter ID_WIDTH = $clog2(SOURCES),
  parameter PIPELINE_STAGES = 3  // Configurable pipeline depth
)(
  input wire clk, rst,
  input wire [SOURCES-1:0] requests,
  input wire input_valid,         // Input valid signal
  output wire input_ready,        // Input ready signal
  output reg [ID_WIDTH-1:0] grant_id,
  output reg grant_valid,
  output reg output_ready         // Output ready signal
);
  // Pipeline stage signals
  reg [SOURCES-1:0] requests_stage1, requests_stage2;
  reg valid_stage1, valid_stage2, valid_stage3;
  reg [ID_WIDTH-1:0] priority_id_stage2, priority_id_stage3;
  reg [ID_WIDTH-1:0] partial_priority_stage2[0:1]; // For parallel priority encoding

  // Flow control signals
  assign input_ready = output_ready || !valid_stage3;

  // Stage 1: Input registration and request detection
  always @(posedge clk) begin
    if (rst) begin
      requests_stage1 <= {SOURCES{1'b0}};
      valid_stage1 <= 1'b0;
    end else if (input_ready) begin
      requests_stage1 <= requests;
      valid_stage1 <= input_valid && (|requests);
    end
  end
  
  // Stage 2: Parallel priority encoding - split into two parallel operations
  always @(posedge clk) begin
    if (rst) begin
      requests_stage2 <= {SOURCES{1'b0}};
      valid_stage2 <= 1'b0;
      partial_priority_stage2[0] <= {ID_WIDTH{1'b0}};
      partial_priority_stage2[1] <= {ID_WIDTH{1'b0}};
    end else begin
      requests_stage2 <= requests_stage1;
      valid_stage2 <= valid_stage1;
      
      // Parallel priority encoding - first half
      partial_priority_stage2[0] <= find_first_one_partial(requests_stage1, 0, SOURCES/2-1);
      
      // Parallel priority encoding - second half
      partial_priority_stage2[1] <= find_first_one_partial(requests_stage1, SOURCES/2, SOURCES-1);
    end
  end
  
  // Stage 3: Final priority resolution and output preparation
  always @(posedge clk) begin
    if (rst) begin
      priority_id_stage3 <= {ID_WIDTH{1'b0}};
      valid_stage3 <= 1'b0;
    end else begin
      // Combine results from parallel paths
      priority_id_stage3 <= select_higher_priority(
                              requests_stage2[SOURCES/2-1:0], partial_priority_stage2[0],
                              requests_stage2[SOURCES-1:SOURCES/2], partial_priority_stage2[1]);
      valid_stage3 <= valid_stage2;
    end
  end
  
  // Output stage
  always @(posedge clk) begin
    if (rst) begin
      grant_id <= {ID_WIDTH{1'b0}};
      grant_valid <= 1'b0;
      output_ready <= 1'b1;
    end else begin
      if (output_ready) begin
        grant_id <= priority_id_stage3;
        grant_valid <= valid_stage3;
        output_ready <= 1'b1; // Always ready in this implementation
      end
    end
  end
  
  // Helper function to find first '1' in a specific range
  function [ID_WIDTH-1:0] find_first_one_partial;
    input [SOURCES-1:0] req_vector;
    input integer start_idx, end_idx;
    reg [ID_WIDTH-1:0] index;
    integer i;
    begin
      index = {ID_WIDTH{1'b0}};
      for (i = end_idx; i >= start_idx; i = i - 1) begin
        if (req_vector[i]) index = i[ID_WIDTH-1:0];
      end
      find_first_one_partial = index;
    end
  endfunction
  
  // Helper function to select higher priority between two results
  function [ID_WIDTH-1:0] select_higher_priority;
    input [SOURCES/2-1:0] low_half_req;
    input [ID_WIDTH-1:0] low_half_id;
    input [SOURCES/2-1:0] high_half_req;
    input [ID_WIDTH-1:0] high_half_id;
    begin
      // Check if there's any request in the higher priority half
      if (|high_half_req)
        select_higher_priority = high_half_id;
      else
        select_higher_priority = low_half_id;
    end
  endfunction
  
endmodule