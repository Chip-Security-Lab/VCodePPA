//SystemVerilog
// SystemVerilog - IEEE 1364-2005
module counter_array #(
    parameter NUM   = 4,
    parameter WIDTH = 4
)(
    input                      clk,
    input                      rst,
    output [NUM*WIDTH-1:0]     cnts
);
    // 内部连线
    wire                       rst_n;
    wire [NUM-1:0]             enable_signals;
    
    // 重置信号处理
    reset_handler u_reset (
        .rst_in     (rst),
        .rst_n_out  (rst_n)
    );
    
    // 使能信号生成
    enable_generator #(
        .NUM        (NUM)
    ) u_enable_gen (
        .en_out     (enable_signals)
    );
    
    // 计数器阵列实例化
    counter_block #(
        .NUM        (NUM),
        .WIDTH      (WIDTH)
    ) u_counter_block (
        .clk        (clk),
        .rst_n      (rst_n),
        .en         (enable_signals),
        .cnts       (cnts)
    );
    
endmodule

module reset_handler (
    input       rst_in,
    output      rst_n_out
);
    // 简单的重置信号反相处理 - 纯组合逻辑
    assign rst_n_out = ~rst_in;
endmodule

module enable_generator #(
    parameter NUM = 4
)(
    output [NUM-1:0] en_out
);
    // 所有计数器均使能 - 纯组合逻辑
    assign en_out = {NUM{1'b1}};
endmodule

module counter_block #(
    parameter NUM   = 4,
    parameter WIDTH = 4
)(
    input                      clk,
    input                      rst_n,
    input  [NUM-1:0]           en,
    output [NUM*WIDTH-1:0]     cnts
);
    // 内部连线，用于保存组合逻辑的下一计数值
    wire [NUM*WIDTH-1:0]       cnt_next_array;
    // 寄存器数组，直接连接到输出
    reg  [NUM*WIDTH-1:0]       cnt_reg_array;
    
    assign cnts = cnt_reg_array;
    
    genvar i;
    generate
        for(i=0; i<NUM; i=i+1) begin : cnt_inst
            single_counter #(
                .WIDTH      (WIDTH)
            ) u_counter (
                .clk        (clk),
                .rst_n      (rst_n),
                .en         (en[i]),
                .current_count(cnt_reg_array[i*WIDTH +: WIDTH]),
                .next_count(cnt_next_array[i*WIDTH +: WIDTH])
            );
        end
    endgenerate
    
    // 时序逻辑部分 - 对所有计数器一次性更新
    always @(posedge clk) begin
        if (!rst_n) 
            cnt_reg_array <= {(NUM*WIDTH){1'b0}};
        else
            for(int j=0; j<NUM; j=j+1) begin
                if (en[j])
                    cnt_reg_array[j*WIDTH +: WIDTH] <= cnt_next_array[j*WIDTH +: WIDTH];
            end
    end
endmodule

module single_counter #(
    parameter WIDTH = 4
)(
    input                  clk,
    input                  rst_n,
    input                  en,
    input      [WIDTH-1:0] current_count,  // 当前计数值输入
    output     [WIDTH-1:0] next_count      // 下一计数值输出
);
    // 组合逻辑部分 - 计算下一个计数值
    counter_comb #(
        .WIDTH(WIDTH)
    ) counter_comb_inst (
        .current_count(current_count),
        .enable(en),
        .next_count(next_count)
    );
endmodule

// 纯组合逻辑模块，负责计数器的下一状态计算
module counter_comb #(
    parameter WIDTH = 4
)(
    input  [WIDTH-1:0] current_count,
    input              enable,
    output [WIDTH-1:0] next_count
);
    // 纯组合逻辑计算下一个计数值
    assign next_count = enable ? (current_count + 1'b1) : current_count;
endmodule