//SystemVerilog
//IEEE 1364-2005 Verilog
// Top-level module
module dynamic_reset_path (
    input wire clk,
    input wire [1:0] path_select,
    input wire [3:0] reset_sources,
    output wire reset_out
);
    // 内部连线
    wire selected_reset;
    
    // 实例化子模块
    reset_source_selector selector_inst (
        .path_select(path_select),
        .reset_sources(reset_sources),
        .selected_reset(selected_reset)
    );
    
    reset_synchronizer sync_inst (
        .clk(clk),
        .reset_in(selected_reset),
        .reset_out(reset_out)
    );
    
endmodule

// 子模块：复用器 - 选择复位源 (纯组合逻辑)
module reset_source_selector (
    input wire [1:0] path_select,
    input wire [3:0] reset_sources,
    output wire selected_reset
);
    // 纯组合逻辑实现
    assign selected_reset = reset_sources[path_select];
    
endmodule

// 子模块：复位同步器 (组合逻辑和时序逻辑分离)
module reset_synchronizer (
    input wire clk,
    input wire reset_in,
    output wire reset_out
);
    // 内部寄存器定义
    reg reset_out_reg;
    
    // 组合逻辑输出连接
    assign reset_out = reset_out_reg;
    
    // 时序逻辑 - 仅在时钟沿触发
    always @(posedge clk) begin
        reset_out_reg <= reset_in;
    end
    
endmodule