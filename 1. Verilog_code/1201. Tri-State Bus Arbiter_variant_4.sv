//SystemVerilog
module tristate_bus_arbiter(
  input wire clk, reset,
  input wire [3:0] req,
  output wire [3:0] grant,
  inout wire [7:0] data_bus,
  input wire [7:0] data_in [3:0],
  output wire [7:0] data_out
);
  // Stage 1: Arbitration stage
  reg [3:0] grant_stage1;
  reg [1:0] current_stage1;
  reg valid_stage1;
  
  // Stage 2: Data selection stage
  reg [3:0] grant_stage2;
  reg valid_stage2;
  reg [7:0] data_drive_stage2;
  
  // Output assignments
  assign grant = grant_stage2;
  assign data_bus = valid_stage2 ? data_drive_stage2 : 8'bz;
  assign data_out = data_bus;
  
  // Stage 1: Arbitration logic
  always @(posedge clk) begin
    if (reset) begin
      grant_stage1 <= 4'h0;
      current_stage1 <= 2'b00;
      valid_stage1 <= 1'b0;
    end else begin
      if (req[current_stage1]) begin
        grant_stage1 <= (4'h1 << current_stage1);
        valid_stage1 <= 1'b1;
      end else begin
        grant_stage1 <= 4'h0;
        valid_stage1 <= 1'b0;
      end
      current_stage1 <= current_stage1 + 1;
    end
  end
  
  // Stage 2: Data selection logic
  always @(posedge clk) begin
    if (reset) begin
      grant_stage2 <= 4'h0;
      valid_stage2 <= 1'b0;
      data_drive_stage2 <= 8'b0;
    end else begin
      grant_stage2 <= grant_stage1;
      valid_stage2 <= valid_stage1;
      
      // Data selection based on grant signals
      if (grant_stage1[0]) 
        data_drive_stage2 <= data_in[0];
      else if (grant_stage1[1]) 
        data_drive_stage2 <= data_in[1];
      else if (grant_stage1[2]) 
        data_drive_stage2 <= data_in[2];
      else if (grant_stage1[3]) 
        data_drive_stage2 <= data_in[3];
      else 
        data_drive_stage2 <= 8'b0;
    end
  end
endmodule