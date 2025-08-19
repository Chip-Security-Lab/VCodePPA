//SystemVerilog
module or_gate_4input_8bit #(
    parameter WIDTH = 8
)(
    input wire [WIDTH-1:0] a,
    input wire [WIDTH-1:0] b,
    input wire [WIDTH-1:0] c,
    input wire [WIDTH-1:0] d,
    output wire [WIDTH-1:0] y
);
    // 内部连线
    wire [WIDTH-1:0] ab_or;
    wire [WIDTH-1:0] cd_or;
    
    // 处理逻辑
    or_unit #(.WIDTH(WIDTH)) ab_stage (
        .in1(a),
        .in2(b),
        .out(ab_or)
    );
    
    or_unit #(.WIDTH(WIDTH)) cd_stage (
        .in1(c),
        .in2(d),
        .out(cd_or)
    );
    
    or_unit #(.WIDTH(WIDTH)) final_stage (
        .in1(ab_or),
        .in2(cd_or),
        .out(y)
    );
endmodule

//SystemVerilog
module or_unit #(
    parameter WIDTH = 8
)(
    input wire [WIDTH-1:0] in1,
    input wire [WIDTH-1:0] in2,
    output wire [WIDTH-1:0] out
);
    // 优化的或运算逻辑
    generate
        for (genvar i = 0; i < WIDTH; i++) begin : gen_or
            assign out[i] = in1[i] | in2[i];
        end
    endgenerate
endmodule