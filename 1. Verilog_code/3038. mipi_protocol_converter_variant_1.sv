//SystemVerilog
// Header conversion module
module header_converter (
  input wire clk,
  input wire reset_n,
  input wire [7:0] src_header,
  input wire [3:0] src_proto,
  input wire [3:0] dst_proto,
  output reg [7:0] converted_header,
  output reg conversion_error
);

  // Protocol conversion lookup table
  function [7:0] convert_header;
    input [7:0] src_header;
    input [3:0] src_proto;
    input [3:0] dst_proto;
    begin
      if (src_proto == 4'd0 && dst_proto == 4'd1) begin
        case (src_header)
          8'h00: convert_header = 8'h01;
          8'h01: convert_header = 8'h02;
          8'h02: convert_header = 8'h03;
          8'h03: convert_header = 8'h04;
          8'h1A: convert_header = 8'h3E;
          default: convert_header = 8'hFF;
        endcase
      end else if (src_proto == 4'd1 && dst_proto == 4'd0) begin
        case (src_header)
          8'h01: convert_header = 8'h00;
          8'h02: convert_header = 8'h01;
          8'h03: convert_header = 8'h02;
          8'h04: convert_header = 8'h03;
          8'h3E: convert_header = 8'h1A;
          default: convert_header = 8'hFF;
        endcase
      end else convert_header = 8'hFF;
    end
  endfunction

  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      converted_header <= 8'd0;
      conversion_error <= 1'b0;
    end else begin
      converted_header <= convert_header(src_header, src_proto, dst_proto);
      conversion_error <= (convert_header(src_header, src_proto, dst_proto) == 8'hFF);
    end
  end

endmodule

// Input buffer module
module input_buffer (
  input wire clk,
  input wire reset_n,
  input wire [31:0] src_data,
  input wire src_valid,
  input wire [3:0] src_protocol,
  input wire [3:0] dst_protocol,
  output reg [31:0] src_data_buf,
  output reg src_valid_buf,
  output reg [3:0] src_protocol_buf,
  output reg [3:0] dst_protocol_buf
);

  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      src_data_buf <= 32'd0;
      src_valid_buf <= 1'b0;
      src_protocol_buf <= 4'd0;
      dst_protocol_buf <= 4'd0;
    end else begin
      src_data_buf <= src_data;
      src_valid_buf <= src_valid;
      src_protocol_buf <= src_protocol;
      dst_protocol_buf <= dst_protocol;
    end
  end

endmodule

// Output controller module
module output_controller (
  input wire clk,
  input wire reset_n,
  input wire [31:0] src_data,
  input wire src_valid,
  input wire [7:0] converted_header,
  input wire conversion_error,
  output reg [31:0] dst_data,
  output reg dst_valid
);

  reg [3:0] state;
  reg [7:0] header_type;

  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      state <= 4'd0;
      dst_valid <= 1'b0;
      dst_data <= 32'd0;
      header_type <= 8'd0;
    end else if (src_valid) begin
      if (state == 4'd0) begin
        header_type <= src_data[7:0];
        if (conversion_error) begin
          dst_valid <= 1'b0;
        end else begin
          dst_data <= {src_data[31:8], converted_header};
          dst_valid <= 1'b1;
          state <= 4'd1;
        end
      end else begin
        dst_data <= src_data;
        dst_valid <= 1'b1;
      end
    end else dst_valid <= 1'b0;
  end

endmodule

// Top level module
module mipi_protocol_converter (
  input wire clk,
  input wire reset_n,
  input wire [31:0] src_data,
  input wire src_valid,
  input wire [3:0] src_protocol,
  input wire [3:0] dst_protocol,
  output wire [31:0] dst_data,
  output wire dst_valid,
  output wire conversion_error
);

  wire [31:0] src_data_buf;
  wire src_valid_buf;
  wire [3:0] src_protocol_buf;
  wire [3:0] dst_protocol_buf;
  wire [7:0] converted_header;

  input_buffer u_input_buffer (
    .clk(clk),
    .reset_n(reset_n),
    .src_data(src_data),
    .src_valid(src_valid),
    .src_protocol(src_protocol),
    .dst_protocol(dst_protocol),
    .src_data_buf(src_data_buf),
    .src_valid_buf(src_valid_buf),
    .src_protocol_buf(src_protocol_buf),
    .dst_protocol_buf(dst_protocol_buf)
  );

  header_converter u_header_converter (
    .clk(clk),
    .reset_n(reset_n),
    .src_header(src_data_buf[7:0]),
    .src_proto(src_protocol_buf),
    .dst_proto(dst_protocol_buf),
    .converted_header(converted_header),
    .conversion_error(conversion_error)
  );

  output_controller u_output_controller (
    .clk(clk),
    .reset_n(reset_n),
    .src_data(src_data_buf),
    .src_valid(src_valid_buf),
    .converted_header(converted_header),
    .conversion_error(conversion_error),
    .dst_data(dst_data),
    .dst_valid(dst_valid)
  );

endmodule