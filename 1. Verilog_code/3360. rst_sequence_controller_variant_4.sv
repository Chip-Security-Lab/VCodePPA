//SystemVerilog
// 顶层模块
module rst_sequence_controller (
    input  wire clk,
    input  wire main_rst_n,
    output wire core_rst_n,
    output wire periph_rst_n,
    output wire mem_rst_n
);
    // 内部信号
    wire synced_rst;
    wire [2:0] counter_value;
    
    // 实例化复位同步子模块
    rst_synchronizer u_rst_sync (
        .clk(clk),
        .async_rst_n(main_rst_n),
        .sync_rst_n(synced_rst)
    );
    
    // 实例化复位序列计数器子模块
    rst_sequence_counter u_rst_counter (
        .clk(clk),
        .sync_rst_n(synced_rst),
        .main_rst_n(main_rst_n),
        .counter(counter_value)
    );
    
    // 实例化复位信号生成子模块
    rst_signal_generator u_rst_signals (
        .clk(clk),
        .counter(counter_value),
        .mem_rst_n(mem_rst_n),
        .periph_rst_n(periph_rst_n),
        .core_rst_n(core_rst_n)
    );
    
endmodule

// 复位同步器子模块
module rst_synchronizer #(
    parameter SYNC_STAGES = 2
)(
    input  wire clk,
    input  wire async_rst_n,
    output wire sync_rst_n
);
    reg [SYNC_STAGES-1:0] rst_sync_reg;
    
    always @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n) begin
            rst_sync_reg <= {SYNC_STAGES{1'b0}};
        end else begin
            rst_sync_reg <= {rst_sync_reg[SYNC_STAGES-2:0], 1'b1};
        end
    end
    
    assign sync_rst_n = rst_sync_reg[SYNC_STAGES-1];
endmodule

// 复位序列计数器子模块 - 优化后
module rst_sequence_counter #(
    parameter COUNTER_WIDTH = 3,
    parameter COUNTER_MAX = 3'b111
)(
    input  wire clk,
    input  wire sync_rst_n,
    input  wire main_rst_n,
    output reg [COUNTER_WIDTH-1:0] counter
);
    wire should_increment;
    
    // 前向寄存器重定时：将增量判断逻辑移到寄存器之前
    assign should_increment = sync_rst_n && (counter != COUNTER_MAX);
    
    always @(posedge clk or negedge main_rst_n) begin
        if (!main_rst_n) begin
            counter <= {COUNTER_WIDTH{1'b0}};
        end else if (should_increment) begin
            counter <= counter + 1'b1;
        end
    end
endmodule

// 复位信号生成器子模块 - 优化后
module rst_signal_generator #(
    parameter MEM_THRESH = 3'b001,
    parameter PERIPH_THRESH = 3'b011,
    parameter CORE_THRESH = 3'b111
)(
    input  wire clk,
    input  wire [2:0] counter,
    output reg mem_rst_n,
    output reg periph_rst_n,
    output reg core_rst_n
);
    // 组合逻辑用于比较
    wire mem_thresh_met = (counter >= MEM_THRESH);
    wire periph_thresh_met = (counter >= PERIPH_THRESH);
    wire core_thresh_met = (counter >= CORE_THRESH);
    
    // 前向寄存器重定时：将比较器输出打拍，降低组合逻辑路径
    always @(posedge clk) begin
        mem_rst_n <= mem_thresh_met;
        periph_rst_n <= periph_thresh_met;
        core_rst_n <= core_thresh_met;
    end
endmodule