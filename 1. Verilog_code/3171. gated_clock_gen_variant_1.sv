//SystemVerilog
// 顶层模块
module gated_clock_gen(
    input  wire master_clk,   // 主时钟输入
    input  wire gate_enable,  // 门控使能信号
    input  wire rst,          // 复位信号
    output wire gated_clk     // 门控后的时钟输出
);
    // 内部信号
    wire enable_latch_out;    // 使能锁存器输出
    
    // 实例化使能锁存子模块
    enable_latch u_enable_latch(
        .master_clk(master_clk),
        .gate_enable(gate_enable),
        .rst(rst),
        .enable_out(enable_latch_out)
    );
    
    // 实例化时钟生成子模块
    clock_generator u_clock_generator(
        .master_clk(master_clk),
        .enable_in(enable_latch_out),
        .gated_clk(gated_clk)
    );
    
endmodule

// 使能锁存子模块
module enable_latch(
    input  wire master_clk,   // 主时钟输入
    input  wire gate_enable,  // 门控使能信号
    input  wire rst,          // 复位信号
    output reg  enable_out    // 锁存后的使能输出
);
    // 在主时钟下降沿捕获使能信号
    always @(negedge master_clk or posedge rst) begin
        if (rst) begin
            enable_out <= 1'b0;
        end else begin
            enable_out <= gate_enable;
        end
    end
endmodule

// 时钟生成子模块
module clock_generator(
    input  wire master_clk,   // 主时钟输入
    input  wire enable_in,    // 使能输入
    output wire gated_clk     // 门控时钟输出
);
    // 生成门控时钟
    assign gated_clk = master_clk & enable_in;
endmodule