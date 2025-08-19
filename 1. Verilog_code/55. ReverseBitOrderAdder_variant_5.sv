//SystemVerilog
// Input pipeline stage module
module input_pipeline(
  input [0:3] vectorA,
  input [0:3] vectorB,
  output reg [0:3] vectorA_reg,
  output reg [0:3] vectorB_reg
);

  always @(*) begin
    vectorA_reg = vectorA;
    vectorB_reg = vectorB;
  end

endmodule

// Computation module
module computation_unit(
  input [0:3] vectorA_reg,
  input [0:3] vectorB_reg,
  output reg [0:4] result_reg
);

  always @(*) begin
    result_reg = vectorA_reg + vectorB_reg;
  end

endmodule

// Top level module
module reverse_add(
  input [0:3] vectorA,
  input [0:3] vectorB,
  output [0:4] result
);

  wire [0:3] vectorA_reg;
  wire [0:3] vectorB_reg;
  wire [0:4] result_reg;

  input_pipeline input_stage(
    .vectorA(vectorA),
    .vectorB(vectorB),
    .vectorA_reg(vectorA_reg),
    .vectorB_reg(vectorB_reg)
  );

  computation_unit compute_stage(
    .vectorA_reg(vectorA_reg),
    .vectorB_reg(vectorB_reg),
    .result_reg(result_reg)
  );

  assign result = result_reg;

endmodule