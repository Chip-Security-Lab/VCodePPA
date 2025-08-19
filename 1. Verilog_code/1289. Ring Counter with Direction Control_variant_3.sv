//SystemVerilog
// 顶层模块
module direction_ring_counter(
    input  wire clk,
    input  wire rst,
    input  wire dir_sel, // Direction select
    output wire [3:0] q_out
);
    // 内部信号
    wire [1:0] control;
    
    // 控制信号生成子模块
    control_generator control_gen_inst (
        .rst(rst),
        .dir_sel(dir_sel),
        .control(control)
    );
    
    // 环形计数器核心逻辑子模块
    ring_counter_core counter_core_inst (
        .clk(clk),
        .control(control),
        .q_out(q_out)
    );
    
endmodule

// 控制信号生成子模块
module control_generator(
    input  wire rst,
    input  wire dir_sel,
    output wire [1:0] control
);
    // 组合控制信号
    assign control = {rst, dir_sel};
endmodule

// 环形计数器核心逻辑子模块
module ring_counter_core(
    input  wire clk,
    input  wire [1:0] control,
    output reg  [3:0] q_out
);
    // 控制码定义
    localparam SHIFT_LEFT  = 2'b00;
    localparam SHIFT_RIGHT = 2'b01;
    localparam RESET       = 2'b10; // 包括2'b11
    
    // 环形计数器逻辑
    always @(posedge clk) begin
        case(control)
            RESET:       q_out <= 4'b0001;                   // Reset condition (priority)
            SHIFT_RIGHT: q_out <= {q_out[0], q_out[3:1]};    // Shift right
            SHIFT_LEFT:  q_out <= {q_out[2:0], q_out[3]};    // Shift left
            default:     q_out <= 4'b0001;                   // Safe default
        endcase
    end
endmodule