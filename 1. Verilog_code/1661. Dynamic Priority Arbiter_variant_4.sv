//SystemVerilog
module dynamic_priority_arbiter(
  input wire clk, rst_n,
  input wire [7:0] requests,
  input wire [23:0] dynamic_priority,
  output reg [7:0] grants
);

  // Stage 1: Priority Extraction and Request Masking
  wire [2:0] priority_array [0:7];
  reg [7:0] masked_req_stage1;
  reg [2:0] current_pri_stage1;
  reg [2:0] highest_pri_stage1;
  reg valid_stage1;

  // Stage 2: Priority Comparison
  reg [2:0] current_pri_stage2;
  reg [2:0] highest_pri_stage2;
  reg valid_stage2;

  // Stage 3: Grant Generation
  reg [7:0] grants_stage3;
  reg valid_stage3;

  // Extract individual priorities - unrolled for loop
  assign priority_array[0] = dynamic_priority[2:0];
  assign priority_array[1] = dynamic_priority[5:3];
  assign priority_array[2] = dynamic_priority[8:6];
  assign priority_array[3] = dynamic_priority[11:9];
  assign priority_array[4] = dynamic_priority[14:12];
  assign priority_array[5] = dynamic_priority[17:15];
  assign priority_array[6] = dynamic_priority[20:18];
  assign priority_array[7] = dynamic_priority[23:21];

  // Stage 1: Priority Extraction
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      masked_req_stage1 <= 8'b0;
      current_pri_stage1 <= 3'b0;
      highest_pri_stage1 <= 3'b0;
      valid_stage1 <= 1'b0;
    end else begin
      masked_req_stage1 <= requests;
      current_pri_stage1 <= priority_array[0];
      highest_pri_stage1 <= 3'b0;
      valid_stage1 <= |requests;
    end
  end

  // Stage 2: Priority Comparison
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      current_pri_stage2 <= 3'b0;
      highest_pri_stage2 <= 3'b0;
      valid_stage2 <= 1'b0;
    end else begin
      current_pri_stage2 <= current_pri_stage1;
      highest_pri_stage2 <= highest_pri_stage1;
      valid_stage2 <= valid_stage1;
    end
  end

  // Stage 3: Grant Generation
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      grants_stage3 <= 8'b0;
      valid_stage3 <= 1'b0;
    end else begin
      grants_stage3 <= 8'b0;
      if (valid_stage2) begin
        grants_stage3[highest_pri_stage2] <= 1'b1;
      end
      valid_stage3 <= valid_stage2;
    end
  end

  // Output assignment
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      grants <= 8'b0;
    end else begin
      grants <= grants_stage3;
    end
  end

endmodule