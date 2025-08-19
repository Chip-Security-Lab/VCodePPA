//SystemVerilog
module dynamic_priority_arbiter(
  input wire clk, rst_n,
  input wire [7:0] requests,
  input wire [23:0] dynamic_priority,
  output reg [7:0] grants
);

  // Stage 1: Priority Extraction and Request Processing
  wire [2:0] priority_array [0:7];
  reg [7:0] masked_req_stage1;
  reg [2:0] current_pri_stage1;
  reg [2:0] highest_pri_stage1;
  reg valid_stage1;

  // Stage 2: Grant Generation
  reg [7:0] grants_stage2;
  reg valid_stage2;

  // Priority extraction
  genvar g;
  generate
    for (g = 0; g < 8; g = g + 1) begin: priority_extract
      assign priority_array[g] = dynamic_priority[g*3 +: 3];
    end
  endgenerate

  // Stage 1: Priority Extraction and Request Processing
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      masked_req_stage1 <= 8'b0;
      current_pri_stage1 <= 3'b0;
      highest_pri_stage1 <= 3'b0;
      valid_stage1 <= 1'b0;
    end else begin
      masked_req_stage1 <= requests;
      valid_stage1 <= |requests;
      
      // Priority comparison logic moved into stage 1
      current_pri_stage1 = 3'b0;
      highest_pri_stage1 = 3'b0;
      for (int i = 0; i < 8; i = i + 1) begin
        if (requests[i] && (priority_array[i] > current_pri_stage1)) begin
          current_pri_stage1 = priority_array[i];
          highest_pri_stage1 = i;
        end
      end
    end
  end

  // Stage 2: Grant Generation
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      grants_stage2 <= 8'b0;
      valid_stage2 <= 1'b0;
    end else begin
      grants_stage2 <= valid_stage1 ? (8'b1 << highest_pri_stage1) : 8'b0;
      valid_stage2 <= valid_stage1;
    end
  end

  // Output assignment
  assign grants = grants_stage2;

endmodule