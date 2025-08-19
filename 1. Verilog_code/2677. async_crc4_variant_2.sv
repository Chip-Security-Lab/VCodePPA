//SystemVerilog
// 顶层模块
module async_crc4 (
    input wire [3:0] data_in,
    output wire [3:0] crc_out
);
    parameter [3:0] POLYNOMIAL = 4'h3; // x^4 + x + 1
    
    wire [3:0] feedback;
    
    // 实例化反馈计算模块
    feedback_generator feedback_gen (
        .data_in(data_in),
        .feedback(feedback)
    );
    
    // 实例化CRC输出模块
    crc_output crc_out_module (
        .feedback(feedback),
        .crc_out(crc_out)
    );
endmodule

// 反馈信号生成模块
module feedback_generator (
    input wire [3:0] data_in,
    output wire [3:0] feedback
);
    // 计算反馈信号
    assign feedback[0] = data_in[0] ^ data_in[3];
    assign feedback[1] = data_in[1] ^ feedback[0];
    assign feedback[2] = data_in[2] ^ feedback[1];
    assign feedback[3] = data_in[3] ^ feedback[2];
endmodule

// CRC输出产生模块
module crc_output (
    input wire [3:0] feedback,
    output wire [3:0] crc_out
);
    // 将反馈信号直接赋值给CRC输出
    assign crc_out = feedback;
endmodule