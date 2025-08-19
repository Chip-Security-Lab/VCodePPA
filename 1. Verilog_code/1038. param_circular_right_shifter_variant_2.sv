//SystemVerilog
// Top-level module: Hierarchical circular right shifter with parameterized width

module param_circular_right_shifter #(
  parameter WIDTH = 8
)(
  input  [WIDTH-1:0]                 data,
  input  [$clog2(WIDTH)-1:0]         rotate,
  output [WIDTH-1:0]                 result
);

  // Internal signal declarations
  wire [6:0] rotate_extended;
  wire [6:0] not_rotate;
  wire [6:0] width_minus_one_vec;
  wire [6:0] temp_sum;
  wire [6:0] width_minus_rotate;
  wire [6:0] shifted_index [0:6];
  wire [WIDTH-1:0] shifted_data;

  // Rotate extension submodule
  rotate_extend #(
    .WIDTH(WIDTH)
  ) u_rotate_extend (
    .rotate_in (rotate),
    .rotate_extended (rotate_extended)
  );

  // Constant vector generator for WIDTH-1
  width_minus_one_vector u_width_minus_one_vector (
    .width_minus_one_vec (width_minus_one_vec)
  );

  // Conditional inverter and subtractor
  conditional_subtractor u_conditional_subtractor (
    .width_minus_one_vec (width_minus_one_vec),
    .rotate_extended     (rotate_extended),
    .not_rotate          (not_rotate),
    .temp_sum            (temp_sum),
    .width_minus_rotate  (width_minus_rotate)
  );

  // Shift index generator
  shift_index_generator u_shift_index_generator (
    .width_minus_rotate (width_minus_rotate),
    .shifted_index     (shifted_index)
  );

  // Circular right shifter core
  circular_right_shifter_core #(
    .WIDTH(WIDTH)
  ) u_circular_right_shifter_core (
    .data           (data),
    .rotate_extended(rotate_extended),
    .shifted_data   (shifted_data)
  );

  // Output assignment
  assign result = shifted_data;

endmodule

// -----------------------------------------------------------------------------
// 子模块：rotate_extend
// 功能：将输入rotate信号扩展为7位（高位补零）
// -----------------------------------------------------------------------------
module rotate_extend #(
  parameter WIDTH = 8
)(
  input  [$clog2(WIDTH)-1:0] rotate_in,
  output [6:0]                rotate_extended
);
  assign rotate_extended = { {(7-$clog2(WIDTH)){1'b0}}, rotate_in };
endmodule

// -----------------------------------------------------------------------------
// 子模块：width_minus_one_vector
// 功能：提供7位的WIDTH-1常量向量（默认为7）
// -----------------------------------------------------------------------------
module width_minus_one_vector(
  output [6:0] width_minus_one_vec
);
  assign width_minus_one_vec = 7'd7;
endmodule

// -----------------------------------------------------------------------------
// 子模块：conditional_subtractor
// 功能：条件反相减法器实现 A-B = A+~B+1
// -----------------------------------------------------------------------------
module conditional_subtractor(
  input  [6:0] width_minus_one_vec,
  input  [6:0] rotate_extended,
  output [6:0] not_rotate,
  output [6:0] temp_sum,
  output [6:0] width_minus_rotate
);
  assign not_rotate = ~rotate_extended;
  assign temp_sum = width_minus_one_vec + not_rotate;
  assign width_minus_rotate = temp_sum + 7'b0000001;
endmodule

// -----------------------------------------------------------------------------
// 子模块：shift_index_generator
// 功能：根据width_minus_rotate生成shifted_index数组（7个元素）
// -----------------------------------------------------------------------------
module shift_index_generator(
  input  [6:0] width_minus_rotate,
  output [6:0] shifted_index [0:6]
);
  genvar gi;
  generate
    for(gi=0; gi<7; gi=gi+1) begin : SHIFT_INDEX_GEN
      assign shifted_index[gi] = (gi + width_minus_rotate) % 7;
    end
  endgenerate
endmodule

// -----------------------------------------------------------------------------
// 子模块：circular_right_shifter_core
// 功能：实现循环右移操作
// -----------------------------------------------------------------------------
module circular_right_shifter_core #(
  parameter WIDTH = 8
)(
  input  [WIDTH-1:0] data,
  input  [6:0]       rotate_extended,
  output [WIDTH-1:0] shifted_data
);
  integer i;
  reg [WIDTH-1:0] shifted_data_reg;

  always @(*) begin
    shifted_data_reg = {WIDTH{1'b0}};
    for(i=0; i<WIDTH; i=i+1) begin
      shifted_data_reg[i] = data[ (i + rotate_extended) % WIDTH ];
    end
  end

  assign shifted_data = shifted_data_reg;
endmodule