//SystemVerilog
// 顶层模块
module async_decoder_en(
    input [1:0] addr,
    input enable,
    output [3:0] decode_out
);
    // 内部信号
    wire [3:0] decoded_value;
    
    // 子模块实例化
    decoder_core decoder_logic(
        .addr(addr),
        .decoded_value(decoded_value)
    );
    
    output_control output_logic(
        .enable(enable),
        .decoded_value(decoded_value),
        .decode_out(decode_out)
    );
    
endmodule

// 译码核心子模块 - 专注于地址译码功能
module decoder_core(
    input [1:0] addr,
    output reg [3:0] decoded_value
);
    always @(*) begin
        case (addr)
            2'b00: decoded_value = 4'b0001;
            2'b01: decoded_value = 4'b0010;
            2'b10: decoded_value = 4'b0100;
            2'b11: decoded_value = 4'b1000;
            default: decoded_value = 4'b0000;
        endcase
    end
endmodule

// 输出控制子模块 - 专注于使能控制功能
module output_control(
    input enable,
    input [3:0] decoded_value,
    output reg [3:0] decode_out
);
    always @(*) begin
        decode_out = enable ? decoded_value : 4'b0000;
    end
endmodule