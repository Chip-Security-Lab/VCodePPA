//SystemVerilog
// 顶层模块
module random_pulse #(
    parameter LFSR_WIDTH = 8,
    parameter SEED = 8'h2B,
    parameter THRESHOLD = 8'h20  // 参数化阈值
)(
    input clk,
    input rst,
    output pulse
);
    // 内部信号
    wire [LFSR_WIDTH-1:0] lfsr_value;
    
    // LFSR子模块实例
    lfsr_generator #(
        .WIDTH(LFSR_WIDTH),
        .SEED(SEED)
    ) lfsr_gen (
        .clk(clk),
        .rst(rst),
        .lfsr_out(lfsr_value)
    );
    
    // 脉冲比较器子模块实例
    pulse_comparator #(
        .WIDTH(LFSR_WIDTH),
        .THRESHOLD(THRESHOLD)
    ) pulse_comp (
        .clk(clk),
        .rst(rst),
        .lfsr_in(lfsr_value),
        .pulse_out(pulse)
    );
endmodule

// LFSR生成器子模块
module lfsr_generator #(
    parameter WIDTH = 8,
    parameter SEED = 8'h2B
)(
    input clk,
    input rst,
    output reg [WIDTH-1:0] lfsr_out
);
    // 多项式抽取为参数，适用于8位LFSR
    wire feedback;
    assign feedback = lfsr_out[7] ^ lfsr_out[3] ^ lfsr_out[2] ^ lfsr_out[0];
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            lfsr_out <= SEED;
        end else begin
            lfsr_out <= {lfsr_out[WIDTH-2:0], feedback};
        end
    end
endmodule

// 脉冲比较器子模块
module pulse_comparator #(
    parameter WIDTH = 8,
    parameter THRESHOLD = 8'h20
)(
    input clk,
    input rst,
    input [WIDTH-1:0] lfsr_in,
    output reg pulse_out
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pulse_out <= 1'b0;
        end else begin
            pulse_out <= (lfsr_in < THRESHOLD);
        end
    end
endmodule