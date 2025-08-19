module thermometer_encoder_top(
    input [2:0] bin,
    output [7:0] th_code
);
    // 实例化条件求和减法器子模块
    conditional_sum_subtractor u_subtractor(
        .bin(bin),
        .th_code(th_code)
    );
endmodule

module conditional_sum_subtractor(
    input [2:0] bin,
    output [7:0] th_code
);
    // 中间信号
    wire [7:0] temp_sum;
    wire [7:0] final_sum;
    
    // 条件求和逻辑
    assign temp_sum[0] = 1'b1;
    assign temp_sum[1] = (bin >= 3'd1) ? 1'b1 : 1'b0;
    assign temp_sum[2] = (bin >= 3'd2) ? 1'b1 : 1'b0;
    assign temp_sum[3] = (bin >= 3'd3) ? 1'b1 : 1'b0;
    assign temp_sum[4] = (bin >= 3'd4) ? 1'b1 : 1'b0;
    assign temp_sum[5] = (bin >= 3'd5) ? 1'b1 : 1'b0;
    assign temp_sum[6] = (bin >= 3'd6) ? 1'b1 : 1'b0;
    assign temp_sum[7] = (bin >= 3'd7) ? 1'b1 : 1'b0;
    
    // 最终输出
    assign th_code = temp_sum;
endmodule