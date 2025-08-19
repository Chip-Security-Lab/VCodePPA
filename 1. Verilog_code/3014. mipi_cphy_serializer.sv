module mipi_cphy_serializer #(parameter WIDTH = 16) (
  input wire clk, reset_n,
  input wire [WIDTH-1:0] data_in,
  input wire valid_in,
  output wire [2:0] trio_out, // 3-wire interface for C-PHY
  output reg ready_out
);
  reg [WIDTH-1:0] buffer;
  reg [5:0] count;
  reg [2:0] symbol;
  
  // 添加encode_symbol实现
  function [2:0] encode_symbol;
    input [2:0] data;
    begin
      case(data)
        3'b000: encode_symbol = 3'b001;
        3'b001: encode_symbol = 3'b010;
        3'b010: encode_symbol = 3'b100;
        3'b011: encode_symbol = 3'b101;
        3'b100: encode_symbol = 3'b011;
        3'b101: encode_symbol = 3'b110;
        3'b110: encode_symbol = 3'b111;
        3'b111: encode_symbol = 3'b000;
        default: encode_symbol = 3'b000;
      endcase
    end
  endfunction
  
  always @(posedge clk or negedge reset_n) begin
    if (!reset_n) begin
      buffer <= {WIDTH{1'b0}};
      count <= 6'd0;
      ready_out <= 1'b1;
      symbol <= 3'b000;
    end else if (valid_in && ready_out) begin
      buffer <= data_in;
      ready_out <= 1'b0;
      count <= 6'd0;
    end else if (!ready_out) begin
      // 提取当前3位并编码为符号
      symbol <= encode_symbol(buffer[count+:3]);
      count <= count + 3;
      if (count >= WIDTH-3) ready_out <= 1'b1;
    end
  end
  
  assign trio_out = symbol;
endmodule