//SystemVerilog
// 顶层模块
module power_opt_divider (
    input  wire clock_i,    // 输入时钟
    input  wire nreset_i,   // 低电平有效复位
    input  wire enable_i,   // 使能信号
    output wire clock_o     // 输出时钟
);
    // 内部连线
    wire cnt_done;
    wire div_out;
    
    // 计数器子模块实例化
    counter_module counter_inst (
        .clock_i   (clock_i),
        .nreset_i  (nreset_i),
        .enable_i  (enable_i),
        .cnt_done  (cnt_done)
    );
    
    // 分频输出子模块实例化
    divider_output_module divider_out_inst (
        .clock_i   (clock_i),
        .nreset_i  (nreset_i),
        .enable_i  (enable_i),
        .cnt_done  (cnt_done),
        .div_out   (div_out)
    );
    
    // 输出门控子模块实例化
    output_gate_module output_gate_inst (
        .div_out   (div_out),
        .enable_i  (enable_i),
        .clock_o   (clock_o)
    );
endmodule

// 计数器子模块
module counter_module (
    input  wire clock_i,    // 输入时钟
    input  wire nreset_i,   // 低电平有效复位
    input  wire enable_i,   // 使能信号
    output wire cnt_done    // 计数完成标志
);
    reg [2:0] div_cnt;
    
    // 计数完成信号生成
    assign cnt_done = (div_cnt == 3'b111);
    
    // 复位逻辑
    always @(negedge nreset_i) begin
        if (!nreset_i) begin
            div_cnt <= 3'b000;
        end
    end
    
    // 计数逻辑
    always @(posedge clock_i) begin
        if (nreset_i) begin
            if (enable_i) begin
                div_cnt <= cnt_done ? 3'b000 : div_cnt + 1'b1;
            end
        end
    end
endmodule

// 分频输出生成子模块
module divider_output_module (
    input  wire clock_i,    // 输入时钟
    input  wire nreset_i,   // 低电平有效复位
    input  wire enable_i,   // 使能信号
    input  wire cnt_done,   // 计数完成信号
    output reg  div_out     // 分频输出
);
    // 复位逻辑
    always @(negedge nreset_i) begin
        if (!nreset_i) begin
            div_out <= 1'b0;
        end
    end
    
    // 分频输出更新逻辑
    always @(posedge clock_i) begin
        if (nreset_i) begin
            if (enable_i && cnt_done) begin
                div_out <= ~div_out;
            end
        end
    end
endmodule

// 输出门控子模块
module output_gate_module (
    input  wire div_out,    // 分频输出
    input  wire enable_i,   // 使能信号
    output wire clock_o     // 最终输出时钟
);
    // 输出门控逻辑
    assign clock_o = div_out & enable_i;
endmodule