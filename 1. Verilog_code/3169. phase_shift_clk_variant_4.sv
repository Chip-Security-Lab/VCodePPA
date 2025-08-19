//SystemVerilog
// Top-level module
module phase_shift_clk #(
    parameter PHASE_BITS = 3
)(
    input clk_in,
    input reset,
    input [PHASE_BITS-1:0] phase_sel,
    output clk_out
);
    wire [PHASE_BITS-1:0] phase_index;
    
    // Phase calculation submodule
    phase_calculator #(
        .PHASE_BITS(PHASE_BITS)
    ) phase_calc_inst (
        .phase_sel(phase_sel),
        .phase_index(phase_index)
    );
    
    // Phase shift register submodule
    phase_shift_register #(
        .PHASE_BITS(PHASE_BITS)
    ) phase_reg_inst (
        .clk_in(clk_in),
        .reset(reset),
        .phase_sel(phase_sel),
        .phase_index(phase_index),
        .clk_out(clk_out)
    );
endmodule

// Phase calculator submodule
module phase_calculator #(
    parameter PHASE_BITS = 3
)(
    input [PHASE_BITS-1:0] phase_sel,
    output [PHASE_BITS-1:0] phase_index
);
    // 使用先行借位减法器实现 phase_index 的计算
    borrow_lookahead_subtractor #(
        .WIDTH(PHASE_BITS)
    ) phase_calc (
        .a(phase_sel),
        .b({(PHASE_BITS){1'b0}}),  // 此处无实际减法，保留接口
        .result(phase_index)
    );
endmodule

// Phase shift register submodule
module phase_shift_register #(
    parameter PHASE_BITS = 3
)(
    input clk_in,
    input reset,
    input [PHASE_BITS-1:0] phase_sel,
    input [PHASE_BITS-1:0] phase_index,
    output reg clk_out
);
    reg [2**PHASE_BITS-1:0] phase_reg;
    
    always @(posedge clk_in or posedge reset) begin
        if (reset) begin
            phase_reg <= {1'b1, {(2**PHASE_BITS-1){1'b0}}};
            clk_out <= 1'b0;
        end else begin
            phase_reg <= {phase_reg[2**PHASE_BITS-2:0], phase_reg[2**PHASE_BITS-1]};
            clk_out <= phase_reg[phase_sel];
        end
    end
endmodule

// 先行借位减法器模块
module borrow_lookahead_subtractor #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output [WIDTH-1:0] result
);
    wire [WIDTH:0] borrow;
    wire [WIDTH-1:0] diff;
    wire [WIDTH-1:0] p; // 传播借位信号
    wire [WIDTH-1:0] g; // 生成借位信号
    
    // 计算初始条件
    assign borrow[0] = 1'b0;
    
    // 计算传播和生成信号
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : borrow_gen
            assign p[i] = ~a[i];           // 传播借位条件
            assign g[i] = ~a[i] & b[i];    // 生成借位条件
            
            // 先行借位计算
            if (i == 0) begin
                assign borrow[i+1] = g[i];
            end else begin
                assign borrow[i+1] = g[i] | (p[i] & borrow[i]);
            end
            
            // 计算差值
            assign diff[i] = a[i] ^ b[i] ^ borrow[i];
        end
    endgenerate
    
    // 输出结果
    assign result = diff;
endmodule