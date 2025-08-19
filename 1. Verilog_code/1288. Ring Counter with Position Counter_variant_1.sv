//SystemVerilog
//IEEE 1364-2005 Verilog

// 顶层模块，负责协调和连接所有子模块
module counting_ring_counter(
    input  wire       clock,
    input  wire       reset,
    output wire [3:0] ring_out,
    output wire [1:0] position
);
    // 内部连线，用于连接子模块
    wire [1:0] next_position;
    wire [3:0] next_ring_out;
    
    // 组合逻辑子模块
    position_calculator u_position_calc(
        .current_position(position),
        .next_position(next_position)
    );
    
    ring_shifter u_ring_shift(
        .current_ring_out(ring_out),
        .next_ring_out(next_ring_out)
    );
    
    // 寄存器子模块
    state_registers u_registers(
        .clock(clock),
        .reset(reset),
        .next_position(next_position),
        .next_ring_out(next_ring_out),
        .position(position),
        .ring_out(ring_out)
    );
endmodule

// 位置计算子模块，负责计算下一个位置
module position_calculator(
    input  wire [1:0] current_position,
    output wire [1:0] next_position
);
    assign next_position = current_position + 1'b1;
endmodule

// 环形移位子模块，负责计算下一个环形输出
module ring_shifter(
    input  wire [3:0] current_ring_out,
    output wire [3:0] next_ring_out
);
    assign next_ring_out = {current_ring_out[2:0], current_ring_out[3]};
endmodule

// 寄存器子模块，负责存储状态
module state_registers(
    input  wire       clock,
    input  wire       reset,
    input  wire [1:0] next_position,
    input  wire [3:0] next_ring_out,
    output reg  [1:0] position,
    output reg  [3:0] ring_out
);
    // 时序逻辑部分
    always @(posedge clock) begin
        if (reset) begin
            ring_out <= 4'b0001;
            position <= 2'b00;
        end
        else begin
            ring_out <= next_ring_out;
            position <= next_position;
        end
    end
endmodule