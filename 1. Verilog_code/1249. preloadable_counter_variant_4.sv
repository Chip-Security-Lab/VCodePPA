//SystemVerilog
module preloadable_counter (
    input wire clk, sync_rst, load, en,
    input wire [5:0] preset_val,
    output wire [5:0] q
);
    // 控制信号处理单元
    wire [2:0] ctrl_signals;
    
    // 计数器状态和控制单元
    wire [5:0] counter_next;
    wire [5:0] counter_reg;
    
    // 控制逻辑子模块
    control_unit ctrl_unit (
        .sync_rst(sync_rst),
        .load(load),
        .en(en),
        .ctrl_signals(ctrl_signals)
    );
    
    // 下一状态计算子模块
    next_state_logic next_state_unit (
        .ctrl_signals(ctrl_signals),
        .preset_val(preset_val),
        .current_count(counter_reg),
        .next_count(counter_next)
    );
    
    // 计数器寄存器子模块
    counter_register counter_reg_unit (
        .clk(clk),
        .next_count(counter_next),
        .count(counter_reg)
    );
    
    // 输出赋值
    assign q = counter_reg;
    
endmodule

// 控制信号处理单元
module control_unit (
    input wire sync_rst, load, en,
    output wire [2:0] ctrl_signals
);
    // 将控制信号组合成一个向量供状态逻辑使用
    assign ctrl_signals = {sync_rst, load, en};
    
endmodule

// 下一状态计算单元
module next_state_logic (
    input wire [2:0] ctrl_signals,
    input wire [5:0] preset_val,
    input wire [5:0] current_count,
    output reg [5:0] next_count
);
    // 基于控制信号计算下一状态
    always @(*) begin
        case (ctrl_signals)
            3'b100, 
            3'b101, 
            3'b110, 
            3'b111: next_count = 6'b000000;  // sync_rst 有效
            
            3'b010, 
            3'b011: next_count = preset_val;  // load 有效，sync_rst 无效
            
            3'b001: next_count = current_count + 1'b1;  // en 有效，load 和 sync_rst 无效
            
            3'b000: next_count = current_count;  // 所有控制信号无效，保持当前值
        endcase
    end
    
endmodule

// 计数器寄存器单元
module counter_register (
    input wire clk,
    input wire [5:0] next_count,
    output reg [5:0] count
);
    // 在时钟上升沿更新计数器值
    always @(posedge clk) begin
        count <= next_count;
    end
    
endmodule