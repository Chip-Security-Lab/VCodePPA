//SystemVerilog
module pipelined_arbiter #(parameter WIDTH=4) (
  input clk, rst,
  input [WIDTH-1:0] req_in,
  output [WIDTH-1:0] grant_out
);
  // Internal signals
  wire [WIDTH-1:0] req_stage1, req_stage2;
  wire [WIDTH-1:0] grant_stage1, grant_stage2;
  
  // Stage 1: Request registration and priority encoding
  request_stage #(
    .WIDTH(WIDTH)
  ) stage1_inst (
    .clk(clk),
    .rst(rst),
    .req_in(req_in),
    .req_out(req_stage1),
    .grant_out(grant_stage1)
  );
  
  // Stage 2: Pipeline register
  pipeline_register #(
    .WIDTH(WIDTH)
  ) stage2_inst (
    .clk(clk),
    .rst(rst),
    .req_in(req_stage1),
    .grant_in(grant_stage1),
    .req_out(req_stage2),
    .grant_out(grant_stage2)
  );
  
  // Output stage: Final grant registration
  output_stage #(
    .WIDTH(WIDTH)
  ) output_inst (
    .clk(clk),
    .rst(rst),
    .grant_in(grant_stage2),
    .grant_out(grant_out)
  );
endmodule

// Stage 1: Request registration and priority encoding
module request_stage #(parameter WIDTH=4) (
  input clk, rst,
  input [WIDTH-1:0] req_in,
  output reg [WIDTH-1:0] req_out,
  output reg [WIDTH-1:0] grant_out
);
  integer i;
  wire [WIDTH-1:0] priority_mask;
  
  // Generate priority mask for efficient one-hot encoding
  assign priority_mask[0] = req_out[0];
  
  // Generate cascaded priority mask
  genvar g;
  generate
    for (g = 1; g < WIDTH; g = g + 1) begin : gen_mask
      assign priority_mask[g] = req_out[g] & ~(|req_out[g-1:0]);
    end
  endgenerate

  always @(posedge clk) begin
    if (rst) begin
      req_out <= {WIDTH{1'b0}};
      grant_out <= {WIDTH{1'b0}};
    end else begin
      req_out <= req_in;
      grant_out <= |req_out ? priority_mask : {WIDTH{1'b0}};
    end
  end
endmodule

// Stage 2: Pipeline register with enable logic for improved power efficiency
module pipeline_register #(parameter WIDTH=4) (
  input clk, rst,
  input [WIDTH-1:0] req_in,
  input [WIDTH-1:0] grant_in,
  output reg [WIDTH-1:0] req_out,
  output reg [WIDTH-1:0] grant_out
);
  wire data_valid;
  assign data_valid = |req_in || |grant_in;
  
  always @(posedge clk) begin
    if (rst) begin
      req_out <= {WIDTH{1'b0}};
      grant_out <= {WIDTH{1'b0}};
    end else if (data_valid) begin
      req_out <= req_in;
      grant_out <= grant_in;
    end
  end
endmodule

// Output stage: Final grant registration with clock gating potential
module output_stage #(parameter WIDTH=4) (
  input clk, rst,
  input [WIDTH-1:0] grant_in,
  output reg [WIDTH-1:0] grant_out
);
  wire grant_change;
  assign grant_change = (grant_in != grant_out);
  
  always @(posedge clk) begin
    if (rst) begin
      grant_out <= {WIDTH{1'b0}};
    end else if (grant_change) begin
      grant_out <= grant_in;
    end
  end
endmodule