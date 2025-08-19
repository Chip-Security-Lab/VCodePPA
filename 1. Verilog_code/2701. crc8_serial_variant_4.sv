//SystemVerilog
module crc8_serial (
    input clk, rst_n, en,
    input [7:0] data_in,
    output [7:0] crc_out
);
    // 内部连线
    wire feedback;
    wire [7:0] xor_result;
    wire [7:0] shift_result;
    wire [7:0] next_crc;
    
    // 参数定义
    parameter POLY = 8'h07;
    
    // 子模块实例化
    crc_feedback_detector feedback_unit (
        .crc_msb(crc_out[7]),
        .feedback(feedback)
    );
    
    crc_xor_calculator xor_unit (
        .feedback(feedback),
        .data_in(data_in),
        .poly(POLY),
        .xor_result(xor_result)
    );
    
    crc_shifter shifter_unit (
        .crc_in(crc_out),
        .shift_result(shift_result)
    );
    
    crc_next_value_selector next_value_unit (
        .shift_result(shift_result),
        .xor_result(xor_result),
        .next_crc(next_crc)
    );
    
    crc_register register_unit (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .next_crc(next_crc),
        .crc_out(crc_out)
    );
endmodule

// 检测CRC最高位，确定是否需要执行异或操作
module crc_feedback_detector (
    input crc_msb,
    output feedback
);
    assign feedback = crc_msb;
endmodule

// 计算CRC异或结果
module crc_xor_calculator (
    input feedback,
    input [7:0] data_in,
    input [7:0] poly,
    output [7:0] xor_result
);
    assign xor_result = feedback ? (poly ^ {data_in, 1'b0}) : {data_in, 1'b0};
endmodule

// 执行CRC移位操作
module crc_shifter (
    input [7:0] crc_in,
    output [7:0] shift_result
);
    assign shift_result = {crc_in[6:0], 1'b0};
endmodule

// 选择下一个CRC值
module crc_next_value_selector (
    input [7:0] shift_result,
    input [7:0] xor_result,
    output [7:0] next_crc
);
    assign next_crc = shift_result ^ xor_result;
endmodule

// CRC寄存器，存储当前CRC值并在时钟上升沿更新
module crc_register (
    input clk, rst_n, en,
    input [7:0] next_crc,
    output reg [7:0] crc_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            crc_out <= 8'hFF;
        else if (en)
            crc_out <= next_crc;
    end
endmodule