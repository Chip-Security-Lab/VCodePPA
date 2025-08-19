//SystemVerilog
//顶层模块
module sawtooth_generator(
    input clock,
    input areset,
    input en,
    output [7:0] sawtooth
);
    // 控制信号
    wire reset_sync;
    wire enable_sync;
    
    // 同步复位和使能信号
    reset_synchronizer reset_sync_inst (
        .clock(clock),
        .async_reset(areset),
        .sync_reset(reset_sync)
    );
    
    enable_controller enable_ctrl_inst (
        .clock(clock),
        .reset(reset_sync),
        .en_in(en),
        .en_out(enable_sync)
    );
    
    // 锯齿波计数器核心
    counter_core counter_inst (
        .clock(clock),
        .reset(reset_sync),
        .enable(enable_sync),
        .count_value(sawtooth)
    );
    
endmodule

// 复位同步器模块 - 拆分为两个独立的always块
module reset_synchronizer (
    input clock,
    input async_reset,
    output reg sync_reset
);
    reg reset_meta;
    
    // 第一级寄存器 - 处理复位信号的捕获
    always @(posedge clock or posedge async_reset) begin
        if (async_reset)
            reset_meta <= 1'b1;
        else
            reset_meta <= 1'b0;
    end
    
    // 第二级寄存器 - 同步输出
    always @(posedge clock or posedge async_reset) begin
        if (async_reset)
            sync_reset <= 1'b1;
        else
            sync_reset <= reset_meta;
    end
endmodule

// 使能控制器模块
module enable_controller (
    input clock,
    input reset,
    input en_in,
    output reg en_out
);
    // 使能信号同步
    always @(posedge clock) begin
        if (reset)
            en_out <= 1'b0;
        else
            en_out <= en_in;
    end
endmodule

// 计数器核心模块 - 拆分为复位逻辑和计数逻辑
module counter_core (
    input clock,
    input reset,
    input enable,
    output reg [7:0] count_value
);
    // 复位逻辑
    wire should_reset;
    reg [7:0] next_count;
    
    // 计算下一个计数值
    always @(*) begin
        if (enable)
            next_count = count_value + 8'h01;
        else
            next_count = count_value;
    end
    
    // 寄存器更新逻辑
    always @(posedge clock or posedge reset) begin
        if (reset)
            count_value <= 8'h00;
        else
            count_value <= next_count;
    end
endmodule