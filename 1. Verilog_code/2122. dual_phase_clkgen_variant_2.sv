//SystemVerilog
// 顶层模块
module dual_phase_clkgen (
    input  wire sys_clk,    // 系统时钟输入
    input  wire async_rst,  // 异步复位信号
    output wire clk_0deg,   // 0度相位时钟输出
    output wire clk_180deg  // 180度相位时钟输出
);
    // 内部连线
    wire phase_toggle;
    
    // 相位切换生成子模块
    phase_generator phase_gen_inst (
        .clk      (sys_clk),
        .rst      (async_rst),
        .phase_out(phase_toggle)
    );
    
    // 时钟输出驱动子模块
    clock_driver clock_driver_inst (
        .clk         (sys_clk),
        .rst         (async_rst),
        .phase_toggle(phase_toggle),
        .clk_0deg    (clk_0deg),
        .clk_180deg  (clk_180deg)
    );
    
endmodule

// 相位切换生成器子模块
module phase_generator (
    input  wire clk,       // 输入时钟
    input  wire rst,       // 异步复位
    output reg  phase_out  // 相位切换输出
);
    
    // 相位切换逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            phase_out <= 1'b0;
        end else begin
            phase_out <= ~phase_out;
        end
    end
    
endmodule

// 时钟驱动器子模块
module clock_driver (
    input  wire clk,          // 输入时钟
    input  wire rst,          // 异步复位
    input  wire phase_toggle, // 相位切换信号
    output reg  clk_0deg,     // 0度相位时钟输出
    output reg  clk_180deg    // 180度相位时钟输出
);
    
    // 时钟输出驱动逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            clk_0deg   <= 1'b0;
            clk_180deg <= 1'b1;
        end else begin
            clk_0deg   <= phase_toggle;
            clk_180deg <= ~phase_toggle;
        end
    end
    
endmodule