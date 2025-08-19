//SystemVerilog
// 顶层模块
module parity_gen #(parameter WIDTH=8, POS="LSB") (
    input [WIDTH-1:0] data_in,
    output [WIDTH:0] data_out
);
    wire parity_bit;
    
    // 实例化校验位生成子模块
    parity_calc #(.WIDTH(WIDTH)) parity_calc_inst (
        .data_in(data_in),
        .parity_bit(parity_bit)
    );
    
    // 实例化数据重组子模块
    data_assembler #(.WIDTH(WIDTH), .POS(POS)) data_assembler_inst (
        .data_in(data_in),
        .parity_bit(parity_bit),
        .data_out(data_out)
    );
endmodule

// 校验位计算子模块
module parity_calc #(parameter WIDTH=8) (
    input [WIDTH-1:0] data_in,
    output parity_bit
);
    assign parity_bit = ^data_in;
endmodule

// 数据重组子模块
module data_assembler #(parameter WIDTH=8, POS="LSB") (
    input [WIDTH-1:0] data_in,
    input parity_bit,
    output reg [WIDTH:0] data_out
);
    always @(*) begin
        data_out = (POS == "MSB") ? {parity_bit, data_in} : {data_in, parity_bit};
    end
endmodule