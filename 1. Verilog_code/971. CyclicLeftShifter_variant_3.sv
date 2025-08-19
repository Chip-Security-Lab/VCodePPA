//SystemVerilog
module CyclicLeftShifter #(
    parameter WIDTH = 8
) (
    input  wire                clk,
    input  wire                rst_n,
    input  wire                en,
    input  wire                serial_in,
    output reg  [WIDTH-1:0]    parallel_out
);
    // 阶段1: 输入缓冲
    reg                 serial_in_reg;
    reg                 en_reg;
    
    // 阶段2: 数据计算路径
    wire [WIDTH-1:0]    shift_stage;
    reg  [WIDTH-1:0]    shift_result;
    
    // 阶段3: 输出选择路径
    reg  [WIDTH-1:0]    next_output;
    
    // 输入缓冲级 - 稳定输入信号
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            serial_in_reg <= 1'b0;
            en_reg <= 1'b0;
        end else begin
            serial_in_reg <= serial_in;
            en_reg <= en;
        end
    end
    
    // 数据计算路径 - 构建移位结果
    assign shift_stage = {parallel_out[WIDTH-2:0], serial_in_reg};
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_result <= {WIDTH{1'b0}};
        end else begin
            shift_result <= shift_stage;
        end
    end
    
    // 输出选择路径 - 根据使能选择输出
    always @(*) begin
        if (en_reg)
            next_output = shift_result;
        else
            next_output = parallel_out;
    end
    
    // 输出更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            parallel_out <= {WIDTH{1'b0}};
        end else begin
            parallel_out <= next_output;
        end
    end
    
endmodule