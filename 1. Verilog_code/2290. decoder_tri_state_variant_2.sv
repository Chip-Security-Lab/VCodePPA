//SystemVerilog
module decoder_tri_state (
    input oe,
    input [2:0] addr,
    output [7:0] bus
);
    wire [7:0] decoded_value;
    
    // 实例化二级结构
    address_decoder addr_decoder_inst (
        .addr(addr),
        .decoded_value(decoded_value)
    );
    
    output_buffer output_buffer_inst (
        .oe(oe),
        .data_in(decoded_value),
        .data_out(bus)
    );
    
endmodule

// 地址解码子模块
module address_decoder (
    input [2:0] addr,
    output [7:0] decoded_value
);
    assign decoded_value = 8'h01 << addr;
endmodule

// 输出缓冲控制子模块
module output_buffer (
    input oe,
    input [7:0] data_in,
    output [7:0] data_out
);
    // 使用条件运算符替代if-else结构
    assign data_out = oe ? data_in : 8'hZZ;
endmodule