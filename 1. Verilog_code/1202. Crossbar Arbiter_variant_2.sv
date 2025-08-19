//SystemVerilog
module crossbar_arbiter #(parameter N=4) (
  input wire clk, rst,
  input wire [N-1:0] src_req,
  input wire [N-1:0] dst_sel [N-1:0],
  output reg [N-1:0] src_gnt,
  output reg [N-1:0] dst_gnt [N-1:0]
);
  // Stage 1: Request processing and conflict detection
  reg [N-1:0] src_req_stage1;
  reg [N-1:0] dst_sel_stage1 [N-1:0];
  reg [N-1:0] dst_conflict_stage1;
  reg [N-1:0] src_valid_stage1;
  
  // Stage 2: Grant generation
  reg [N-1:0] src_req_stage2;
  reg [N-1:0] dst_sel_stage2 [N-1:0];
  reg [N-1:0] dst_conflict_stage2;
  reg [N-1:0] src_valid_stage2;
  
  // Pipeline control signal
  reg pipeline_valid_stage1;
  
  integer i, j;
  
  // Stage 1: Request processing and destination conflict detection
  always @(posedge clk) begin
    if (rst) begin
      src_req_stage1 <= 0;
      for (i = 0; i < N; i = i + 1) dst_sel_stage1[i] <= 0;
      dst_conflict_stage1 <= 0;
      src_valid_stage1 <= 0;
      pipeline_valid_stage1 <= 0;
    end else begin
      // Register inputs
      src_req_stage1 <= src_req;
      for (i = 0; i < N; i = i + 1) dst_sel_stage1[i] <= dst_sel[i];
      
      // Identify destination conflicts
      dst_conflict_stage1 <= 0;
      for (i = 0; i < N; i = i + 1) begin
        for (j = 0; j < N; j = j + 1) begin
          if (src_req[i] && dst_sel[i][j]) begin
            for (integer k = i+1; k < N; k = k + 1) begin
              if (src_req[k] && dst_sel[k][j]) begin
                dst_conflict_stage1[j] <= 1'b1;
              end
            end
          end
        end
      end
      
      // Mark valid source requests
      src_valid_stage1 <= src_req;
      
      // Set pipeline stage valid
      pipeline_valid_stage1 <= 1'b1;
    end
  end
  
  // Stage 2: Grant generation based on request and conflict information
  always @(posedge clk) begin
    if (rst) begin
      src_req_stage2 <= 0;
      for (i = 0; i < N; i = i + 1) dst_sel_stage2[i] <= 0;
      dst_conflict_stage2 <= 0;
      src_valid_stage2 <= 0;
      src_gnt <= 0;
      for (i = 0; i < N; i = i + 1) dst_gnt[i] <= 0;
    end else begin
      // Forward pipeline registers
      src_req_stage2 <= src_req_stage1;
      for (i = 0; i < N; i = i + 1) dst_sel_stage2[i] <= dst_sel_stage1[i];
      dst_conflict_stage2 <= dst_conflict_stage1;
      src_valid_stage2 <= src_valid_stage1;
      
      // Default grant values
      src_gnt <= 0;
      for (i = 0; i < N; i = i + 1) dst_gnt[i] <= 0;
      
      // Generate grants only if pipeline is valid
      if (pipeline_valid_stage1) begin
        // Priority-based arbitration for each destination
        for (i = 0; i < N; i = i + 1) begin
          if (src_valid_stage2[i]) begin
            for (j = 0; j < N; j = j + 1) begin
              if (dst_sel_stage2[i][j] && !dst_conflict_stage2[j]) begin
                src_gnt[i] <= 1'b1;
                dst_gnt[j] <= 1'b1;
                // Once granted, mark destination as used to prevent multiple grants
                dst_conflict_stage2[j] <= 1'b1;
              end
            end
          end
        end
      end
    end
  end
endmodule