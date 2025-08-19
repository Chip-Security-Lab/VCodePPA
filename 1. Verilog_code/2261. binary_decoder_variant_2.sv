//SystemVerilog
// 顶层模块
module binary_decoder(
    input [3:0] addr_in,
    output [15:0] select_out
);
    // 内部连线
    wire [3:0] decoded_addr;
    wire [15:0] decoded_output;
    
    // 子模块实例化
    address_buffer addr_buffer_inst (
        .addr_in(addr_in),
        .addr_out(decoded_addr)
    );
    
    decode_logic decode_logic_inst (
        .addr(decoded_addr),
        .select_out(decoded_output)
    );
    
    output_register output_reg_inst (
        .data_in(decoded_output),
        .data_out(select_out)
    );
    
endmodule

// 地址缓冲子模块
module address_buffer(
    input [3:0] addr_in,
    output [3:0] addr_out
);
    // 简单缓冲以改善时序
    assign addr_out = addr_in;
endmodule

// 解码逻辑子模块
module decode_logic(
    input [3:0] addr,
    output reg [15:0] select_out
);
    // 执行实际的解码操作
    always @(*) begin
        select_out = 16'b0;
        select_out[addr] = 1'b1;
    end
endmodule

// 输出寄存器子模块
module output_register(
    input [15:0] data_in,
    output [15:0] data_out
);
    // 直接连接，可根据需要添加寄存器逻辑以改善时序
    assign data_out = data_in;
endmodule