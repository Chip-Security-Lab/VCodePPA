//SystemVerilog
// 顶层模块
module arithmetic_shift_right (
    input signed [31:0] data_in,
    input [4:0] shift,
    output signed [31:0] data_out
);
    // 内部信号
    wire sign_bit;
    wire [31:0] shift_mask;
    wire [31:0] shifted_data;
    
    // 子模块实例化
    sign_extractor sign_ext_inst (
        .data_in(data_in),
        .sign_bit(sign_bit)
    );
    
    mask_generator mask_gen_inst (
        .shift(shift),
        .sign_bit(sign_bit),
        .shift_mask(shift_mask)
    );
    
    bit_shifter shifter_inst (
        .data_in(data_in),
        .shift(shift),
        .shifted_data(shifted_data)
    );
    
    result_composer result_comp_inst (
        .shifted_data(shifted_data),
        .shift_mask(shift_mask),
        .data_out(data_out)
    );
    
endmodule

// 符号位提取子模块
module sign_extractor (
    input signed [31:0] data_in,
    output sign_bit
);
    assign sign_bit = data_in[31];
endmodule

// 移位掩码生成子模块
module mask_generator (
    input [4:0] shift,
    input sign_bit,
    output [31:0] shift_mask
);
    wire [31:0] all_ones;
    wire [31:0] shifted_ones;
    
    assign all_ones = {32{sign_bit}};
    assign shifted_ones = (shift == 0) ? 32'b0 : (all_ones << (32 - shift));
    assign shift_mask = shifted_ones;
endmodule

// 位移操作子模块
module bit_shifter (
    input signed [31:0] data_in,
    input [4:0] shift,
    output [31:0] shifted_data
);
    assign shifted_data = data_in >> shift;
endmodule

// 结果合成子模块
module result_composer (
    input [31:0] shifted_data,
    input [31:0] shift_mask,
    output signed [31:0] data_out
);
    assign data_out = shifted_data | shift_mask;
endmodule