//SystemVerilog
// 顶层模块
module loadable_ring_counter(
    input wire clock,
    input wire reset,
    input wire load,
    input wire [3:0] data_in,
    output wire [3:0] ring_out
);
    // 内部连线
    wire [1:0] ctrl_signals;
    
    // 控制信号生成子模块
    control_generator ctrl_gen (
        .reset(reset),
        .load(load),
        .ctrl(ctrl_signals)
    );
    
    // 环形计数器更新逻辑子模块
    counter_update_logic counter_logic (
        .clock(clock),
        .ctrl(ctrl_signals),
        .data_in(data_in),
        .ring_out(ring_out)
    );
    
endmodule

// 控制信号生成子模块
module control_generator(
    input wire reset,
    input wire load,
    output reg [1:0] ctrl
);
    // 提取共同控制信号
    always @(*) begin
        ctrl = {reset, load};
    end
endmodule

// 环形计数器更新逻辑子模块
module counter_update_logic(
    input wire clock,
    input wire [1:0] ctrl,
    input wire [3:0] data_in,
    output reg [3:0] ring_out
);
    // 状态更新逻辑
    always @(posedge clock) begin
        case(ctrl)
            2'b10, 2'b11: ring_out <= 4'b0001;    // reset优先
            2'b01:        ring_out <= data_in;    // load
            2'b00:        ring_out <= {ring_out[2:0], ring_out[3]};  // 正常移位
            default:      ring_out <= 4'b0001;    // 安全默认值
        endcase
    end
endmodule