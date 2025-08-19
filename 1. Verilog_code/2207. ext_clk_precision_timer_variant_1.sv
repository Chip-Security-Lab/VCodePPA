//SystemVerilog - IEEE 1364-2005
module ext_clk_precision_timer #(
    parameter WIDTH = 20
)(
    input wire ext_clk,
    input wire sys_clk,
    input wire rst_n,
    input wire start,
    input wire stop,
    output reg busy,
    output reg [WIDTH-1:0] elapsed_time
);
    reg [WIDTH-1:0] counter;
    reg running;
    
    // 使用两级触发器进行时钟域同步
    reg start_meta, start_sync;
    reg stop_meta, stop_sync;
    
    // 边沿检测信号
    reg start_sync_prev, stop_sync_prev;
    wire start_edge, stop_edge;
    
    // 优化的计数器实现
    wire [WIDTH-1:0] counter_next;
    
    // 为高扇出信号添加寄存器缓冲
    reg running_buf1, running_buf2;
    reg [WIDTH/2-1:0] counter_upper_buf1, counter_upper_buf2;
    reg [WIDTH/2-1:0] counter_lower_buf1, counter_lower_buf2;
    
    // 改进的时钟域同步逻辑 - 使用外部时钟域
    always @(posedge ext_clk or negedge rst_n) begin
        if (!rst_n) begin
            start_meta <= 1'b0;
            start_sync <= 1'b0;
            start_sync_prev <= 1'b0;
            stop_meta <= 1'b0;
            stop_sync <= 1'b0;
            stop_sync_prev <= 1'b0;
        end else begin
            // 两级触发器减少亚稳态风险
            start_meta <= start;
            start_sync <= start_meta;
            start_sync_prev <= start_sync;
            
            stop_meta <= stop;
            stop_sync <= stop_meta;
            stop_sync_prev <= stop_sync;
        end
    end
    
    // 边沿检测 - 检测上升沿
    assign start_edge = start_sync && !start_sync_prev;
    assign stop_edge = stop_sync && !stop_sync_prev;
    
    // 添加扇出缓冲寄存器
    always @(posedge ext_clk or negedge rst_n) begin
        if (!rst_n) begin
            running_buf1 <= 1'b0;
            running_buf2 <= 1'b0;
            counter_upper_buf1 <= {(WIDTH/2){1'b0}};
            counter_upper_buf2 <= {(WIDTH/2){1'b0}};
            counter_lower_buf1 <= {(WIDTH/2){1'b0}};
            counter_lower_buf2 <= {(WIDTH/2){1'b0}};
        end else begin
            // 分散running的负载
            running_buf1 <= running;
            running_buf2 <= running;
            
            // 分散counter的负载 - 上半部分和下半部分
            counter_upper_buf1 <= counter[WIDTH-1:WIDTH/2];
            counter_upper_buf2 <= counter[WIDTH-1:WIDTH/2];
            counter_lower_buf1 <= counter[WIDTH/2-1:0];
            counter_lower_buf2 <= counter[WIDTH/2-1:0];
        end
    end
    
    // 优化的计数器逻辑 - 使用扇出缓冲的信号进行加法
    // 将加法操作拆分成两个部分以减少关键路径延迟
    wire carry;
    wire [WIDTH/2-1:0] lower_sum;
    wire [WIDTH/2-1:0] upper_sum;
    
    assign {carry, lower_sum} = counter_lower_buf1 + running_buf1;
    assign upper_sum = counter_upper_buf2 + carry;
    
    assign counter_next = {upper_sum, lower_sum};
    
    // 外部时钟域计数器逻辑
    always @(posedge ext_clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= {WIDTH{1'b0}};
            running <= 1'b0;
            busy <= 1'b0;
            elapsed_time <= {WIDTH{1'b0}};
        end else begin
            if (start_edge) begin
                counter <= {WIDTH{1'b0}};
                running <= 1'b1;
                busy <= 1'b1;
            end else if (stop_edge && running) begin
                running <= 1'b0;
                elapsed_time <= counter;
                busy <= 1'b0;
            end else if (running) begin
                counter <= counter_next;
            end
        end
    end
endmodule