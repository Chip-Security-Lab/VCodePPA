//SystemVerilog
// CDC synchronization module
module cdc_sync #(parameter DW=16)(
  input clkA, clkB,
  input [DW-1:0] data_in,
  output reg [DW-1:0] sync_out
);
  reg [DW-1:0] sync_reg1;
  
  always @(posedge clkA) begin
    sync_reg1 <= data_in;
  end
  
  always @(posedge clkB) begin
    sync_out <= sync_reg1;
  end
endmodule

// Priority encoder module
module prio_enc #(parameter DW=16)(
  input clk, rst,
  input [DW-1:0] data_in,
  output reg [$clog2(DW)-1:0] enc_out,
  output reg valid_out
);
  reg [DW-1:0] data_stage1, data_stage2;
  reg valid_stage1, valid_stage2;
  reg [$clog2(DW)-1:0] enc_stage1, enc_stage2;
  
  // Pipeline stage 1
  always @(posedge clk) begin
    if (rst) begin
      data_stage1 <= 0;
      valid_stage1 <= 0;
      enc_stage1 <= 0;
    end else begin
      data_stage1 <= data_in;
      valid_stage1 <= |data_in;
      
      enc_stage1 <= 0;
      for (integer i = 0; i < DW/2; i = i + 1) begin
        if (data_in[i]) enc_stage1 <= i[$clog2(DW)-1:0];
      end
    end
  end
  
  // Pipeline stage 2
  always @(posedge clk) begin
    if (rst) begin
      data_stage2 <= 0;
      valid_stage2 <= 0;
      enc_stage2 <= 0;
    end else begin
      data_stage2 <= data_stage1;
      valid_stage2 <= valid_stage1;
      
      if (valid_stage1) begin
        if (|data_stage1[DW-1:DW/2]) begin
          enc_stage2 <= 0;
          for (integer i = DW/2; i < DW; i = i + 1) begin
            if (data_stage1[i]) enc_stage2 <= i[$clog2(DW)-1:0];
          end
        end else begin
          enc_stage2 <= enc_stage1;
        end
      end else begin
        enc_stage2 <= 0;
      end
    end
  end
  
  // Output stage
  always @(posedge clk) begin
    if (rst) begin
      enc_out <= 0;
      valid_out <= 0;
    end else begin
      enc_out <= enc_stage2;
      valid_out <= valid_stage2;
    end
  end
endmodule

// Top module
module prio_enc_cdc #(parameter DW=16)(
  input clkA, clkB, rst,
  input [DW-1:0] data_in,
  output [$clog2(DW)-1:0] sync_out
);
  wire [DW-1:0] cdc_out;
  wire valid_out;
  
  cdc_sync #(.DW(DW)) cdc_inst(
    .clkA(clkA),
    .clkB(clkB),
    .data_in(data_in),
    .sync_out(cdc_out)
  );
  
  prio_enc #(.DW(DW)) enc_inst(
    .clk(clkB),
    .rst(rst),
    .data_in(cdc_out),
    .enc_out(sync_out),
    .valid_out(valid_out)
  );
endmodule