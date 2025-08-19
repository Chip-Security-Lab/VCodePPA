//SystemVerilog
module delay_ff #(
    parameter STAGES = 4  // 流水线级数
) (
    input  wire clk,      // 时钟输入
    input  wire rst_n,    // 异步复位信号
    input  wire d,        // 数据输入
    output wire q         // 数据输出
);

    // 内部信号声明
    reg stage1_data;
    reg stage2_data;
    reg [STAGES-3:0] middle_stages; // 中间级寄存器组
    
    // 组合逻辑部分 - 输出逻辑
    assign q = (STAGES <= 2) ? stage2_data : middle_stages[STAGES-3];
    
    // 时序逻辑部分
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_data <= 1'b0;
        end
        else begin
            stage1_data <= d;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_data <= 1'b0;
        end
        else begin
            stage2_data <= stage1_data;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            middle_stages <= {(STAGES-2){1'b0}};
        end
        else if (STAGES > 2) begin
            middle_stages <= {middle_stages[STAGES-4:0], stage2_data};
        end
    end

endmodule