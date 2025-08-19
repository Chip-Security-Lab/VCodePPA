//SystemVerilog
// 顶层模块
module onehot_input_decoder (
    input  [7:0] onehot_in,
    output [2:0] binary_out,
    output       valid
);
    // 子模块实例化
    onehot_validity_checker u_validity_checker (
        .onehot_in  (onehot_in),
        .valid      (valid)
    );

    onehot_to_binary_converter u_binary_converter (
        .onehot_in   (onehot_in),
        .binary_out  (binary_out)
    );
endmodule

// 子模块1：独热码有效性检查器
module onehot_validity_checker (
    input  [7:0] onehot_in,
    output reg   valid
);
    // 检测输入是否有效（是否为独热码）
    always @(*) begin
        case (onehot_in)
            8'b00000001: valid = 1'b1;
            8'b00000010: valid = 1'b1;
            8'b00000100: valid = 1'b1;
            8'b00001000: valid = 1'b1;
            8'b00010000: valid = 1'b1;
            8'b00100000: valid = 1'b1;
            8'b01000000: valid = 1'b1;
            8'b10000000: valid = 1'b1;
            default:     valid = 1'b0;
        endcase
    end
endmodule

// 子模块2：独热码到二进制转换器
module onehot_to_binary_converter (
    input  [7:0] onehot_in,
    output reg [2:0] binary_out
);
    // 独热码到二进制码的转换
    always @(*) begin
        case (1'b1) // 优先级编码器模式
            onehot_in[0]: binary_out = 3'b000;
            onehot_in[1]: binary_out = 3'b001;
            onehot_in[2]: binary_out = 3'b010;
            onehot_in[3]: binary_out = 3'b011;
            onehot_in[4]: binary_out = 3'b100;
            onehot_in[5]: binary_out = 3'b101;
            onehot_in[6]: binary_out = 3'b110;
            onehot_in[7]: binary_out = 3'b111;
            default:      binary_out = 3'b000;
        endcase
    end
endmodule