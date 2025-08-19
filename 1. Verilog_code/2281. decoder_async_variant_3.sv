//SystemVerilog
// 顶层模块
module decoder_async #(parameter AW=4, DW=16) (
    input [AW-1:0] addr,
    output [DW-1:0] decoded
);
    // 内部连线
    wire addr_in_range;
    wire [DW-1:0] decoded_value;
    wire [DW-1:0] default_value;
    
    // 子模块实例化
    addr_range_check #(
        .AW(AW),
        .DW(DW)
    ) u_addr_range_check (
        .addr(addr),
        .addr_valid(addr_in_range)
    );
    
    decode_generator #(
        .AW(AW),
        .DW(DW)
    ) u_decode_generator (
        .addr(addr),
        .decoded_value(decoded_value)
    );
    
    output_mux #(
        .DW(DW)
    ) u_output_mux (
        .addr_in_range(addr_in_range),
        .decoded_value(decoded_value),
        .default_value(default_value),
        .decoded(decoded)
    );
    
    default_value_gen #(
        .DW(DW)
    ) u_default_value_gen (
        .default_value(default_value)
    );
    
endmodule

// 地址范围检查子模块
module addr_range_check #(parameter AW=4, DW=16) (
    input [AW-1:0] addr,
    output addr_valid
);
    // 检查地址是否在有效范围内
    assign addr_valid = (addr < DW);
    
endmodule

// 解码值生成子模块
module decode_generator #(parameter AW=4, DW=16) (
    input [AW-1:0] addr,
    output [DW-1:0] decoded_value
);
    // 根据地址生成解码值
    assign decoded_value = 1'b1 << addr;
    
endmodule

// 默认值生成子模块
module default_value_gen #(parameter DW=16) (
    output [DW-1:0] default_value
);
    // 生成默认值(全0)
    assign default_value = {DW{1'b0}};
    
endmodule

// 输出多路选择器子模块
module output_mux #(parameter DW=16) (
    input addr_in_range,
    input [DW-1:0] decoded_value,
    input [DW-1:0] default_value,
    output [DW-1:0] decoded
);
    // 根据地址范围选择输出值
    assign decoded = addr_in_range ? decoded_value : default_value;
    
endmodule