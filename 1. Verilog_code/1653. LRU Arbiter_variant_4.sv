//SystemVerilog
module lru_arbiter #(parameter N = 4) (
  input clk, rst,
  input [N-1:0] request,
  output [N-1:0] grant,
  output busy
);

  // Request handler submodule
  request_handler #(.N(N)) req_handler (
    .clk(clk),
    .rst(rst),
    .request(request),
    .grant(grant),
    .busy(busy)
  );

endmodule

module request_handler #(parameter N = 4) (
  input clk, rst,
  input [N-1:0] request,
  output reg [N-1:0] grant,
  output reg busy
);

  // Pipeline registers
  reg [N-1:0] request_stage1, request_stage2;
  reg busy_stage1, busy_stage2;
  reg found_stage1, found_stage2;
  reg [$clog2(N)-1:0] priority_index_stage1, priority_index_stage2;
  reg valid_stage1, valid_stage2;
  
  // First pipeline stage - Request detection and validation
  always @(posedge clk) begin
    if (rst) begin
      request_stage1 <= 0;
      busy_stage1 <= 0;
      valid_stage1 <= 0;
    end else begin
      request_stage1 <= request;
      busy_stage1 <= |request;
      valid_stage1 <= |request;
    end
  end
  
  // Second pipeline stage - Priority encoding (first half of indices)
  always @(posedge clk) begin
    if (rst) begin
      found_stage1 <= 0;
      priority_index_stage1 <= 0;
    end else if (valid_stage1) begin
      found_stage1 <= 0;
      priority_index_stage1 <= 0;
      
      // Check first half of indices
      for (integer i = 0; i < N/2; i = i + 1) begin
        if (!found_stage1 && request_stage1[i]) begin
          priority_index_stage1 <= i;
          found_stage1 <= 1;
        end
      end
    end
  end
  
  // Third pipeline stage - Priority encoding (second half of indices)
  always @(posedge clk) begin
    if (rst) begin
      found_stage2 <= 0;
      priority_index_stage2 <= 0;
      request_stage2 <= 0;
      busy_stage2 <= 0;
      valid_stage2 <= 0;
    end else begin
      request_stage2 <= request_stage1;
      busy_stage2 <= busy_stage1;
      valid_stage2 <= valid_stage1;
      
      // Pass through result from first half if found
      if (found_stage1) begin
        found_stage2 <= 1;
        priority_index_stage2 <= priority_index_stage1;
      end else if (valid_stage1) begin
        // Check second half of indices
        found_stage2 <= 0;
        priority_index_stage2 <= 0;
        
        for (integer i = N/2; i < N; i = i + 1) begin
          if (!found_stage2 && request_stage1[i]) begin
            priority_index_stage2 <= i;
            found_stage2 <= 1;
          end
        end
      end else begin
        found_stage2 <= 0;
      end
    end
  end
  
  // Final pipeline stage - Output generation
  always @(posedge clk) begin
    if (rst) begin
      grant <= 0;
      busy <= 0;
    end else begin
      busy <= busy_stage2;
      
      if (valid_stage2 && found_stage2) begin
        grant <= (1'b1 << priority_index_stage2);
      end else if (valid_stage2 && !found_stage2) begin
        grant <= 0;
      end else begin
        grant <= 0;
      end
    end
  end

endmodule