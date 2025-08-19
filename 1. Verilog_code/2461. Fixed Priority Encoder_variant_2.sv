//SystemVerilog
`timescale 1ns / 1ps

// Top level module - Interrupt Controller
module fixed_priority_intr_ctrl #(
  parameter INT_WIDTH = 8,
  parameter ID_WIDTH = 3
)(
  input  wire                  clk,
  input  wire                  rst_n,
  input  wire [INT_WIDTH-1:0]  intr_src,
  output wire [ID_WIDTH-1:0]   intr_id,
  output wire                  intr_valid
);

  // Internal wires for connecting submodules
  wire [INT_WIDTH-1:0] intr_src_buf1;
  wire [INT_WIDTH-1:0] intr_src_buf2;

  // Instantiate input buffer module
  intr_input_buffer #(
    .INT_WIDTH(INT_WIDTH)
  ) u_intr_input_buffer (
    .clk          (clk),
    .rst_n        (rst_n),
    .intr_src     (intr_src),
    .intr_src_buf1(intr_src_buf1),
    .intr_src_buf2(intr_src_buf2)
  );

  // Instantiate interrupt valid signal generator
  intr_valid_gen #(
    .INT_WIDTH(INT_WIDTH)
  ) u_intr_valid_gen (
    .clk        (clk),
    .rst_n      (rst_n),
    .intr_src   (intr_src_buf1),
    .intr_valid (intr_valid)
  );

  // Instantiate priority encoder module
  priority_encoder #(
    .INT_WIDTH(INT_WIDTH),
    .ID_WIDTH (ID_WIDTH)
  ) u_priority_encoder (
    .clk          (clk),
    .rst_n        (rst_n),
    .intr_src_buf2(intr_src_buf2),
    .intr_id      (intr_id)
  );

endmodule

// Input buffer module - Handles buffering of interrupt sources
module intr_input_buffer #(
  parameter INT_WIDTH = 8
)(
  input  wire                  clk,
  input  wire                  rst_n,
  input  wire [INT_WIDTH-1:0]  intr_src,
  output reg  [INT_WIDTH-1:0]  intr_src_buf1,
  output reg  [INT_WIDTH-1:0]  intr_src_buf2
);

  // First level buffer register for intr_src
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      intr_src_buf1 <= {INT_WIDTH{1'b0}};
    end else begin
      intr_src_buf1 <= intr_src;
    end
  end
  
  // Second level buffer register to further distribute load
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      intr_src_buf2 <= {INT_WIDTH{1'b0}};
    end else begin
      intr_src_buf2 <= intr_src_buf1;
    end
  end

endmodule

// Valid signal generator module
module intr_valid_gen #(
  parameter INT_WIDTH = 8
)(
  input  wire                  clk,
  input  wire                  rst_n,
  input  wire [INT_WIDTH-1:0]  intr_src,
  output reg                   intr_valid
);

  // Valid signal generation
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      intr_valid <= 1'b0;
    end else begin
      intr_valid <= |intr_src;
    end
  end

endmodule

// Priority encoder module
module priority_encoder #(
  parameter INT_WIDTH = 8,
  parameter ID_WIDTH = 3
)(
  input  wire                  clk,
  input  wire                  rst_n,
  input  wire [INT_WIDTH-1:0]  intr_src_buf2,
  output reg  [ID_WIDTH-1:0]   intr_id
);

  // Priority encoding logic with parameterizable width
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      intr_id <= {ID_WIDTH{1'b0}};
    end else begin
      intr_id <= encode_priority(intr_src_buf2);
    end
  end

  // Function to determine priority encoding
  function [ID_WIDTH-1:0] encode_priority;
    input [INT_WIDTH-1:0] intr;
    integer i;
    begin
      encode_priority = {ID_WIDTH{1'b0}};
      for (i = INT_WIDTH-1; i >= 0; i = i - 1) begin
        if (intr[i]) begin
          encode_priority = i[ID_WIDTH-1:0];
        end
      end
    end
  endfunction

endmodule