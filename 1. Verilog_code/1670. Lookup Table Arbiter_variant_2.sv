//SystemVerilog
// LUT Arbiter Top Module
module lut_arbiter(
  input clk, rst,
  input [3:0] req,
  output reg [3:0] grant,
  output reg ack
);

  // Internal signals
  wire [3:0] lut_output;
  wire [3:0] req_reg;
  wire req_valid;
  
  // LUT Memory Module
  lut_memory lut_mem_inst(
    .clk(clk),
    .rst(rst),
    .addr(req_reg),
    .data(lut_output)
  );
  
  // Request Handler Module
  request_handler req_handler_inst(
    .clk(clk),
    .rst(rst),
    .req(req),
    .req_reg(req_reg),
    .req_valid(req_valid)
  );
  
  // Grant Generator Module
  grant_generator grant_gen_inst(
    .clk(clk),
    .rst(rst),
    .req_valid(req_valid),
    .lut_output(lut_output),
    .grant(grant),
    .ack(ack)
  );

endmodule

// LUT Memory Module
module lut_memory(
  input clk, rst,
  input [3:0] addr,
  output reg [3:0] data
);
  
  reg [3:0] lut [0:15];
  
  always @(posedge clk) begin
    if (rst) begin
      lut[0] <= 4'b0000; lut[1] <= 4'b0001;
      lut[2] <= 4'b0010; lut[3] <= 4'b0001;
      data <= 4'b0000;
    end else begin
      data <= lut[addr];
    end
  end
endmodule

// Request Handler Module
module request_handler(
  input clk, rst,
  input [3:0] req,
  output reg [3:0] req_reg,
  output reg req_valid
);
  
  always @(posedge clk) begin
    if (rst) begin
      req_reg <= 4'b0000;
      req_valid <= 1'b0;
    end else begin
      if (!req_valid && req != 4'b0000) begin
        req_reg <= req;
        req_valid <= 1'b1;
      end else if (req_valid) begin
        req_valid <= 1'b0;
      end
    end
  end
endmodule

// Grant Generator Module
module grant_generator(
  input clk, rst,
  input req_valid,
  input [3:0] lut_output,
  output reg [3:0] grant,
  output reg ack
);
  
  always @(posedge clk) begin
    if (rst) begin
      grant <= 4'b0000;
      ack <= 1'b0;
    end else begin
      if (req_valid) begin
        grant <= lut_output;
        ack <= 1'b1;
      end else begin
        ack <= 1'b0;
      end
    end
  end
endmodule