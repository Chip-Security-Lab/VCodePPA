//SystemVerilog
module shadow_buffer (
    input wire clk,
    input wire rst_n,          // 添加复位信号
    input wire [31:0] data_in,
    input wire capture,
    input wire update,
    input wire valid_in,       // 输入有效信号
    output wire ready_in,      // 输入就绪信号
    output reg valid_out,      // 输出有效信号
    input wire ready_out,      // 输出就绪信号
    output reg [31:0] data_out
);
    // 流水线阶段1 - 捕获数据
    reg [31:0] stage1_data;
    reg stage1_valid;
    reg stage1_update;
    
    // 流水线阶段2 - 影子缓存
    reg [31:0] stage2_shadow;
    reg stage2_valid;
    reg stage2_update;
    
    // 流水线控制
    wire stage1_ready;
    wire stage2_ready;
    
    assign stage1_ready = ~stage1_valid | stage2_ready;
    assign stage2_ready = ~stage2_valid | (ready_out & stage2_update) | ~stage2_update;
    assign ready_in = stage1_ready;
    
    // 流水线阶段1处理 - 捕获数据
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_data <= 32'b0;
            stage1_valid <= 1'b0;
            stage1_update <= 1'b0;
        end
        else if (stage1_ready) begin
            if (valid_in) begin
                stage1_data <= capture ? data_in : stage1_data;
                stage1_valid <= 1'b1;
                stage1_update <= update;
            end
            else begin
                stage1_valid <= 1'b0;
            end
        end
    end
    
    // 流水线阶段2处理 - 影子缓存和输出
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_shadow <= 32'b0;
            stage2_valid <= 1'b0;
            stage2_update <= 1'b0;
        end
        else if (stage2_ready) begin
            if (stage1_valid) begin
                stage2_shadow <= stage1_data;
                stage2_valid <= stage1_valid;
                stage2_update <= stage1_update;
            end
            else begin
                stage2_valid <= 1'b0;
            end
        end
    end
    
    // 输出处理
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 32'b0;
            valid_out <= 1'b0;
        end
        else if (ready_out) begin
            if (stage2_valid && stage2_update) begin
                data_out <= stage2_shadow;
                valid_out <= 1'b1;
            end
            else begin
                valid_out <= 1'b0;
            end
        end
    end
endmodule