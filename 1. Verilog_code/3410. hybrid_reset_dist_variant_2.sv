//SystemVerilog
module hybrid_reset_dist(
    input wire clk,
    input wire async_rst,
    input wire sync_rst,
    input wire [3:0] mode_select,
    output wire [3:0] reset_out
);
    // 组合逻辑信号
    wire [1:0] reset_state;
    
    // 时序逻辑输出
    reg [3:0] reset_out_reg;
    
    // 组合逻辑模块实例化
    reset_state_logic reset_logic_inst (
        .async_rst(async_rst),
        .sync_rst(sync_rst),
        .reset_state(reset_state)
    );
    
    // 时序逻辑模块实例化
    reset_output_logic reset_output_inst (
        .clk(clk),
        .async_rst(async_rst),
        .reset_state(reset_state),
        .mode_select(mode_select),
        .reset_out(reset_out_reg)
    );
    
    // 输出赋值
    assign reset_out = reset_out_reg;
    
endmodule

// 组合逻辑模块
module reset_state_logic(
    input wire async_rst,
    input wire sync_rst,
    output reg [1:0] reset_state
);
    // 纯组合逻辑
    always @(*) begin
        // 合并重置条件为单个控制变量
        case ({async_rst, sync_rst})
            2'b10, 2'b11: reset_state = 2'b01; // 异步复位优先
            2'b01:        reset_state = 2'b10; // 同步复位次之
            2'b00:        reset_state = 2'b00; // 无复位
            default:      reset_state = 2'b01; // 默认异步复位
        endcase
    end
endmodule

// 时序逻辑模块
module reset_output_logic(
    input wire clk,
    input wire async_rst,
    input wire [1:0] reset_state,
    input wire [3:0] mode_select,
    output reg [3:0] reset_out
);
    // 纯时序逻辑
    always @(posedge clk or posedge async_rst) begin
        if (async_rst && reset_state == 2'b01) begin
            // 异步复位
            reset_out <= 4'b1111;
        end
        else begin
            case (reset_state)
                2'b01:   reset_out <= 4'b1111;            // 异步复位
                2'b10:   reset_out <= mode_select & 4'b1111; // 同步复位
                2'b00:   reset_out <= 4'b0000;            // 无复位
                default: reset_out <= 4'b1111;            // 默认安全状态
            endcase
        end
    end
endmodule