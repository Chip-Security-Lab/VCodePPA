//SystemVerilog
// Top module
module RD6 #(parameter WIDTH=8, DEPTH=4)(
  input clk, 
  input arstn,
  input [WIDTH-1:0] shift_in,
  output [WIDTH-1:0] shift_out
);
  // Internal signals
  wire [WIDTH-1:0] stage1_out;
  wire reset_buffered;
  
  // Reset buffer module instance
  ResetBuffer u_reset_buffer (
    .clk(clk),
    .arstn(arstn),
    .reset_buffered(reset_buffered)
  );
  
  // First shift register stage
  FirstStageShiftReg #(.WIDTH(WIDTH), .STAGE_DEPTH(DEPTH/2)) u_first_stage (
    .clk(clk),
    .arstn(arstn),
    .shift_in(shift_in),
    .stage_out(stage1_out)
  );
  
  // Second shift register stage
  SecondStageShiftReg #(.WIDTH(WIDTH), .STAGE_DEPTH(DEPTH/2)) u_second_stage (
    .clk(clk),
    .arstn(reset_buffered),
    .shift_in(stage1_out),
    .shift_out(shift_out)
  );
endmodule

// Reset buffering module
module ResetBuffer (
  input clk,
  input arstn,
  output reset_buffered
);
  // Buffered reset signal to reduce fanout
  reg [1:0] arstn_buf;
  
  always @(posedge clk or negedge arstn) begin
    if (!arstn) begin
      arstn_buf <= 2'b00;
    end else begin
      arstn_buf <= {arstn_buf[0], 1'b1};
    end
  end
  
  assign reset_buffered = arstn_buf[1];
endmodule

// First stage shift register module
module FirstStageShiftReg #(parameter WIDTH=8, STAGE_DEPTH=2)(
  input clk,
  input arstn,
  input [WIDTH-1:0] shift_in,
  output [WIDTH-1:0] stage_out
);
  // Register array for first stage
  reg [WIDTH-1:0] shreg [0:STAGE_DEPTH-1];
  // Buffer for output stage
  reg [WIDTH-1:0] stage_out_buf;
  
  integer j;
  
  // Shift register logic
  always @(posedge clk or negedge arstn) begin
    if (!arstn) begin
      for (j=0; j<STAGE_DEPTH; j=j+1) begin
        shreg[j] <= 0;
      end
    end else begin
      shreg[0] <= shift_in;
      for (j=1; j<STAGE_DEPTH; j=j+1) begin
        shreg[j] <= shreg[j-1];
      end
    end
  end
  
  // Buffer the output signal
  always @(posedge clk) begin
    stage_out_buf <= shreg[STAGE_DEPTH-1];
  end
  
  assign stage_out = stage_out_buf;
endmodule

// Second stage shift register module
module SecondStageShiftReg #(parameter WIDTH=8, STAGE_DEPTH=2)(
  input clk,
  input arstn,
  input [WIDTH-1:0] shift_in,
  output [WIDTH-1:0] shift_out
);
  // Register array for second stage
  reg [WIDTH-1:0] shreg [0:STAGE_DEPTH-1];
  
  integer j;
  
  // Shift register logic
  always @(posedge clk or negedge arstn) begin
    if (!arstn) begin
      for (j=0; j<STAGE_DEPTH; j=j+1) begin
        shreg[j] <= 0;
      end
    end else begin
      shreg[0] <= shift_in;
      for (j=1; j<STAGE_DEPTH; j=j+1) begin
        shreg[j] <= shreg[j-1];
      end
    end
  end
  
  assign shift_out = shreg[STAGE_DEPTH-1];
endmodule