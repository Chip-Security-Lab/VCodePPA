//SystemVerilog
// LUT Memory Module
module lut_memory(
  input wire [3:0] addr,
  output reg [3:0] data
);
  
  reg [3:0] lut [0:15];
  
  always @(*) begin
    data = lut[addr];
  end

  initial begin
    lut[0] = 4'b0000; lut[1] = 4'b0001;
    lut[2] = 4'b0010; lut[3] = 4'b0001;
    lut[4] = 4'b0100; lut[5] = 4'b0001;
    lut[6] = 4'b0010; lut[7] = 4'b0001;
    lut[8] = 4'b1000; lut[9] = 4'b0001;
    lut[10] = 4'b0010; lut[11] = 4'b0001;
    lut[12] = 4'b0100; lut[13] = 4'b0001;
    lut[14] = 4'b0010; lut[15] = 4'b0001;
  end

endmodule

// Pipeline Register Module
module pipeline_reg #(
  parameter WIDTH = 4
)(
  input wire clk,
  input wire rst,
  input wire [WIDTH-1:0] din,
  output reg [WIDTH-1:0] dout
);

  always @(posedge clk) begin
    if (rst) begin
      dout <= {WIDTH{1'b0}};
    end else begin
      dout <= din;
    end
  end

endmodule

// Top Level Module
module lut_arbiter(
  input wire clk,
  input wire rst,
  input wire [3:0] request,
  output reg [3:0] grant
);

  wire [3:0] request_reg;
  wire [3:0] grant_reg;
  wire [3:0] lut_data;

  // Request pipeline stage
  pipeline_reg #(.WIDTH(4)) request_pipe (
    .clk(clk),
    .rst(rst),
    .din(request),
    .dout(request_reg)
  );

  // LUT memory
  lut_memory lut_inst (
    .addr(request_reg),
    .data(lut_data)
  );

  // Grant pipeline stage
  pipeline_reg #(.WIDTH(4)) grant_pipe (
    .clk(clk),
    .rst(rst),
    .din(lut_data),
    .dout(grant_reg)
  );

  // Output stage
  pipeline_reg #(.WIDTH(4)) output_pipe (
    .clk(clk),
    .rst(rst),
    .din(grant_reg),
    .dout(grant)
  );

endmodule