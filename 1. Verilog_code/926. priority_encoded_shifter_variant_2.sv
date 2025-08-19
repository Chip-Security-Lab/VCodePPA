//SystemVerilog
// 顶层模块
module priority_encoded_shifter(
    input [7:0] data,
    input [2:0] priority_shift, // Priority-encoded shift amount
    output [7:0] result
);
    wire [2:0] actual_shift;
    
    // 实例化优先级编码器子模块
    priority_encoder priority_enc_inst (
        .priority_in(priority_shift),
        .shift_amount(actual_shift)
    );
    
    // 实例化移位器子模块
    barrel_shifter shifter_inst (
        .data_in(data),
        .shift_amount(actual_shift),
        .data_out(result)
    );
    
endmodule

// 优先级编码器子模块
module priority_encoder (
    input [2:0] priority_in,
    output reg [2:0] shift_amount
);
    // 优化使用并行逻辑，减少级联逻辑延迟
    always @(*) begin
        case (priority_in)
            3'b1??: shift_amount = 3'd4; // Highest priority, don't care about lower bits
            3'b01?: shift_amount = 3'd2; // Medium priority
            3'b001: shift_amount = 3'd1; // Lowest priority
            default: shift_amount = 3'd0; // No shift
        endcase
    end
endmodule

// 桶式移位器子模块
module barrel_shifter (
    input [7:0] data_in,
    input [2:0] shift_amount,
    output [7:0] data_out
);
    // 使用参数化设计，提高可配置性
    parameter WIDTH = 8;
    
    // 优化移位逻辑，避免使用常规的移位运算符，
    // 实现更高效的桶式移位器结构
    reg [WIDTH-1:0] shifted;
    
    always @(*) begin
        case (shift_amount)
            3'd0: shifted = data_in;
            3'd1: shifted = {data_in[WIDTH-2:0], 1'b0};
            3'd2: shifted = {data_in[WIDTH-3:0], 2'b00};
            3'd4: shifted = {data_in[WIDTH-5:0], 4'b0000};
            default: shifted = data_in;
        endcase
    end
    
    assign data_out = shifted;
endmodule