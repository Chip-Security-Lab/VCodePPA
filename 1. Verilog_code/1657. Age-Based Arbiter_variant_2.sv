//SystemVerilog
module age_based_arbiter #(parameter CLIENTS = 6) (
  input clk, reset,
  input [CLIENTS-1:0] requests,
  output reg [CLIENTS-1:0] grants
);

  // Stage 1: Age counter update
  reg [3:0] age [0:CLIENTS-1];
  reg [CLIENTS-1:0] requests_stage1;
  reg [CLIENTS-1:0] grants_stage1;
  
  always @(posedge clk) begin
    if (reset) begin
      for (integer i = 0; i < CLIENTS; i = i + 1) begin
        age[i] <= 0;
      end
      requests_stage1 <= 0;
      grants_stage1 <= 0;
    end else begin
      requests_stage1 <= requests;
      grants_stage1 <= grants;
      
      for (integer i = 0; i < CLIENTS; i = i + 1) begin
        if (requests_stage1[i] && !grants_stage1[i]) begin
          age[i] <= age[i] + 1;
        end
      end
    end
  end

  // Stage 2: Age comparison
  reg [3:0] max_age_stage2;
  reg [CLIENTS-1:0] oldest_requester_stage2;
  reg [CLIENTS-1:0] requests_stage2;
  
  always @(posedge clk) begin
    if (reset) begin
      max_age_stage2 <= 0;
      oldest_requester_stage2 <= 0;
      requests_stage2 <= 0;
    end else begin
      requests_stage2 <= requests_stage1;
      max_age_stage2 <= 0;
      oldest_requester_stage2 <= 0;
      
      for (integer i = 0; i < CLIENTS; i = i + 1) begin
        if (requests_stage2[i] && age[i] > max_age_stage2) begin
          max_age_stage2 <= age[i];
          oldest_requester_stage2 <= (1 << i);
        end
      end
    end
  end

  // Stage 3: Grant generation
  always @(posedge clk) begin
    if (reset) begin
      grants <= 0;
    end else begin
      grants <= oldest_requester_stage2;
    end
  end

endmodule