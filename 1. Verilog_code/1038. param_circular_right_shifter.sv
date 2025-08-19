module param_circular_right_shifter #(
  parameter WIDTH = 8
)(
  input [WIDTH-1:0] data,
  input [$clog2(WIDTH)-1:0] rotate,
  output [WIDTH-1:0] result
);
  // 使用组合逻辑处理所有可能的rotate值
  reg [WIDTH-1:0] shifted_data;
  
  integer i;
  always @(*) begin
    shifted_data = data;
    case(rotate)
      3'd0: shifted_data = data;
      3'd1: shifted_data = {data[0], data[WIDTH-1:1]};
      3'd2: shifted_data = {data[1:0], data[WIDTH-1:2]};
      3'd3: shifted_data = {data[2:0], data[WIDTH-1:3]};
      3'd4: shifted_data = {data[3:0], data[WIDTH-1:4]};
      3'd5: shifted_data = {data[4:0], data[WIDTH-1:5]};
      3'd6: shifted_data = {data[5:0], data[WIDTH-1:6]};
      3'd7: shifted_data = {data[6:0], data[WIDTH-1:7]};
    endcase
  end
  
  assign result = shifted_data;
endmodule