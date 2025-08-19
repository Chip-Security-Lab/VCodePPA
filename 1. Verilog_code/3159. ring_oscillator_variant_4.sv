//SystemVerilog
// 顶层模块
module ring_oscillator(
    input enable,
    output clk_out
);
    wire [4:0] chain;
    
    // 振荡器核心
    oscillator_core osc_core (
        .enable(enable),
        .chain_in(chain[4]),
        .chain_out(chain[0])
    );
    
    // 反相器链
    inverter_chain inv_chain (
        .chain_in(chain[0]),
        .chain_out(chain[4])
    );
    
    // 输出缓冲
    output_buffer out_buf (
        .signal_in(chain[4]),
        .signal_out(clk_out)
    );
endmodule

// 振荡器核心模块 - 处理使能控制和反馈
module oscillator_core (
    input enable,
    input chain_in,
    output reg chain_out
);
    // 将条件运算符转换为if-else结构
    always @(*) begin
        if (enable) begin
            chain_out = ~chain_in;
        end else begin
            chain_out = 1'b0;
        end
    end
endmodule

// 反相器链模块 - 提供所需的延迟和相位
module inverter_chain (
    input chain_in,
    output chain_out
);
    wire [3:0] internal;
    
    // 参数化设计，便于调整反相器数量
    parameter INVERTER_COUNT = 4;
    
    // 第一级反相器
    inverter_stage inv1 (
        .in(chain_in),
        .out(internal[0])
    );
    
    // 中间级反相器
    inverter_stage inv2 (
        .in(internal[0]),
        .out(internal[1])
    );
    
    inverter_stage inv3 (
        .in(internal[1]),
        .out(internal[2])
    );
    
    // 最后级反相器
    inverter_stage inv4 (
        .in(internal[2]),
        .out(chain_out)
    );
endmodule

// 单个反相器级
module inverter_stage (
    input in,
    output reg out
);
    // 使用always块替代assign以优化PPA
    always @(*) begin
        out = ~in;
    end
endmodule

// 输出缓冲模块 - 提供足够的驱动能力
module output_buffer (
    input signal_in,
    output reg signal_out
);
    // 使用always块优化缓冲器以提高驱动能力
    always @(*) begin
        signal_out = signal_in;
    end
endmodule