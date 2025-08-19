//SystemVerilog (IEEE 1364-2005)
module multisource_timer #(
    parameter COUNTER_WIDTH = 16
)(
    input wire clk_src_0,
    input wire clk_src_1,
    input wire clk_src_2,
    input wire clk_src_3,
    input wire [1:0] clk_sel,
    input wire rst_n,
    input wire [COUNTER_WIDTH-1:0] threshold,
    output reg event_out
);
    reg [COUNTER_WIDTH-1:0] counter;
    wire selected_clk;
    
    // 时钟选择逻辑
    reg clk_mux;
    
    always @(*) begin
        case(clk_sel)
            2'b00: clk_mux = clk_src_0;
            2'b01: clk_mux = clk_src_1;
            2'b10: clk_mux = clk_src_2;
            2'b11: clk_mux = clk_src_3;
        endcase
    end
    
    // 高扇出信号缓冲策略 - 将clk_mux分配给多个缓冲寄存器
    reg clk_buf1, clk_buf2;
    
    // 第一级缓冲
    always @(*) begin
        clk_buf1 = clk_mux;
        clk_buf2 = clk_mux;
    end
    
    // 第二级缓冲及分配
    reg clk_counter_buf;
    reg clk_event_buf;
    
    always @(*) begin
        clk_counter_buf = clk_buf1;
        clk_event_buf = clk_buf2;
    end
    
    // 使用缓冲后的时钟信号
    assign selected_clk = clk_counter_buf;
    
    // 阈值比较器优化 - 提前计算比较结果
    wire counter_at_threshold;
    assign counter_at_threshold = (counter == threshold - 1'b1);
    
    // 计数器逻辑 - 使用缓冲后的时钟
    always @(posedge selected_clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= {COUNTER_WIDTH{1'b0}};
        end else begin
            if (counter_at_threshold) begin
                counter <= {COUNTER_WIDTH{1'b0}};
            end else begin
                counter <= counter + 1'b1;
            end
        end
    end
    
    // 事件输出逻辑 - 使用另一个缓冲时钟以平衡负载
    always @(posedge clk_event_buf or negedge rst_n) begin
        if (!rst_n) begin
            event_out <= 1'b0;
        end else begin
            event_out <= counter_at_threshold;
        end
    end
endmodule