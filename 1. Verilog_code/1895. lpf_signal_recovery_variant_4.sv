//SystemVerilog
module lpf_signal_recovery #(
    parameter WIDTH = 12,
    parameter ALPHA = 4 // Alpha/16 portion of new sample
)(
    input wire clock,
    input wire reset,
    input wire [WIDTH-1:0] raw_sample,
    output wire [WIDTH-1:0] filtered
);
    // Internal signals
    reg [WIDTH-1:0] raw_sample_reg;
    reg [WIDTH-1:0] filtered_reg;
    reg [WIDTH+4:0] mul_alpha_raw;
    reg [WIDTH+4:0] mul_1minusalpha_filtered;
    reg [WIDTH-1:0] filtered_output;
    
    wire [WIDTH+4:0] new_filtered;
    
    // 组合逻辑模块实例化
    lpf_combinational_logic #(
        .WIDTH(WIDTH),
        .ALPHA(ALPHA)
    ) comb_logic (
        .raw_sample(raw_sample_reg),
        .filtered_reg(filtered_reg),
        .mul_alpha_raw(mul_alpha_raw),
        .mul_1minusalpha_filtered(mul_1minusalpha_filtered),
        .new_filtered(new_filtered)
    );
    
    // 时序逻辑 - 第一阶段寄存器
    always @(posedge clock) begin
        if (reset) begin
            raw_sample_reg <= 0;
            filtered_reg <= 0;
            mul_alpha_raw <= 0;
            mul_1minusalpha_filtered <= 0;
        end else begin
            raw_sample_reg <= raw_sample;
            filtered_reg <= filtered_output;
            mul_alpha_raw <= ALPHA * raw_sample;
            mul_1minusalpha_filtered <= (16-ALPHA) * filtered_output;
        end
    end
    
    // 时序逻辑 - 输出寄存器
    always @(posedge clock) begin
        if (reset)
            filtered_output <= 0;
        else
            filtered_output <= new_filtered[WIDTH-1:0];
    end
    
    // 连接输出
    assign filtered = filtered_output;
    
endmodule

// 组合逻辑模块
module lpf_combinational_logic #(
    parameter WIDTH = 12,
    parameter ALPHA = 4
)(
    input wire [WIDTH-1:0] raw_sample,
    input wire [WIDTH-1:0] filtered_reg,
    input wire [WIDTH+4:0] mul_alpha_raw,
    input wire [WIDTH+4:0] mul_1minusalpha_filtered,
    output wire [WIDTH+4:0] new_filtered
);
    // 组合逻辑计算
    assign new_filtered = (mul_1minusalpha_filtered + mul_alpha_raw) >> 4;
    
endmodule