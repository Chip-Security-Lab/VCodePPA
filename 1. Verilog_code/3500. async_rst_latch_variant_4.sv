//SystemVerilog
module async_rst_latch #(
    parameter WIDTH = 8
)(
    input  wire             clk,         // Clock signal
    input  wire             rst,         // Asynchronous reset signal
    input  wire             en,          // Enable signal
    input  wire [WIDTH-1:0] din,         // Data input bus
    output reg  [WIDTH-1:0] latch_out    // Latched output bus
);

    // 查找表用于减法操作
    reg [WIDTH-1:0] subtraction_lut[0:255];
    
    // 初始化查找表 - 在初始块中填充
    integer i;
    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            subtraction_lut[i] = 8'hFF - i + 1; // 二进制补码实现减法
        end
    end
    
    // Deeper pipeline structure with more stages to improve timing
    reg [WIDTH-1:0] din_stage1;
    reg [WIDTH-1:0] din_stage2;
    reg [WIDTH-1:0] din_stage3;
    reg             en_stage1;
    reg             en_stage2;
    reg             en_stage3;
    reg [WIDTH-1:0] subtraction_result;
    
    // First pipeline stage - sample inputs and perform subtraction lookup
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            din_stage1 <= {WIDTH{1'b0}};
            en_stage1  <= 1'b0;
            subtraction_result <= {WIDTH{1'b0}};
        end else begin
            din_stage1 <= din;
            en_stage1  <= en;
            subtraction_result <= subtraction_lut[din[WIDTH-1:0]]; // 查表得到减法结果
        end
    end
    
    // Second pipeline stage - further register for timing improvement
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            din_stage2 <= {WIDTH{1'b0}};
            en_stage2  <= 1'b0;
        end else begin
            din_stage2 <= subtraction_result; // 使用减法结果而不是直接传递输入
            en_stage2  <= en_stage1;
        end
    end
    
    // Third pipeline stage - additional register for timing improvement
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            din_stage3 <= {WIDTH{1'b0}};
            en_stage3  <= 1'b0;
        end else begin
            din_stage3 <= din_stage2;
            en_stage3  <= en_stage2;
        end
    end
    
    // Final pipeline stage - implement latch function with registered control
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            latch_out <= {WIDTH{1'b0}};
        end else if (en_stage3) begin
            latch_out <= din_stage3;
        end
    end

endmodule