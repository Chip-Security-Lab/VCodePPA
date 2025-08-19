//SystemVerilog
//=============================================================================
// 顶层模块：时钟分频器
//=============================================================================
module rom_clkdiv #(
    parameter MAX = 50000000
)(
    input  wire clk,
    output wire clk_out
);
    // 内部信号
    wire counter_max_reached;
    
    // 子模块实例化
    counter_module #(
        .MAX(MAX)
    ) counter_inst (
        .clk              (clk),
        .counter_max_reached (counter_max_reached)
    );
    
    toggle_module toggle_inst (
        .clk              (clk),
        .trigger          (counter_max_reached),
        .toggle_out       (clk_out)
    );
    
endmodule

//=============================================================================
// 子模块：计数器
//=============================================================================
module counter_module #(
    parameter MAX = 50000000
)(
    input  wire clk,
    output reg  counter_max_reached
);
    // 内部寄存器
    reg [25:0] counter;
    reg [25:0] max_val;
    
    // 初始化
    initial begin
        counter <= 26'd0;
        max_val <= MAX;
        counter_max_reached <= 1'b0;
    end
    
    // 计数逻辑
    always @(posedge clk) begin
        if(counter >= max_val) begin
            counter <= 26'd0;
            counter_max_reached <= 1'b1;
        end else begin
            counter <= counter + 1'b1;
            counter_max_reached <= 1'b0;
        end
    end
endmodule

//=============================================================================
// 子模块：翻转器
//=============================================================================
module toggle_module (
    input  wire clk,
    input  wire trigger,
    output reg  toggle_out
);
    // 初始化
    initial begin
        toggle_out <= 1'b0;
    end
    
    // 翻转逻辑
    always @(posedge clk) begin
        if(trigger) begin
            toggle_out <= ~toggle_out;
        end
    end
endmodule