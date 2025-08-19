//SystemVerilog
//IEEE 1364-2005 Verilog

// 顶层模块
module error_detect_decoder(
    input [1:0] addr,
    input valid,
    output [3:0] select,
    output error
);
    // 内部连线
    wire [1:0] addr_to_decoder;
    wire valid_to_decoder;
    
    // 错误检测子模块实例
    error_detection_unit error_detection_inst (
        .valid_in(valid),
        .error_out(error),
        .valid_out(valid_to_decoder)
    );
    
    // 地址寄存器子模块实例
    address_register_unit addr_register_inst (
        .addr_in(addr),
        .valid_in(valid),
        .addr_out(addr_to_decoder)
    );
    
    // 解码器子模块实例
    decoder_unit decoder_inst (
        .addr(addr_to_decoder),
        .valid(valid_to_decoder),
        .select(select)
    );
endmodule

// 错误检测子模块
module error_detection_unit(
    input valid_in,
    output error_out,
    output valid_out
);
    assign error_out = ~valid_in;
    assign valid_out = valid_in;
endmodule

// 地址寄存器子模块
module address_register_unit(
    input [1:0] addr_in,
    input valid_in,
    output [1:0] addr_out
);
    assign addr_out = addr_in;
endmodule

// 解码器子模块
module decoder_unit(
    input [1:0] addr,
    input valid,
    output reg [3:0] select
);
    always @(*) begin
        if (valid) begin
            case (addr)
                2'b00: select = 4'b0001;
                2'b01: select = 4'b0010;
                2'b10: select = 4'b0100;
                2'b11: select = 4'b1000;
                default: select = 4'b0000;
            endcase
        end
        else begin
            select = 4'b0000;
        end
    end
endmodule