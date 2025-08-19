//SystemVerilog
module or_gate_3input_1bit (
    input wire clk,      
    input wire rst_n,    
    input wire a,
    input wire b,
    input wire c,
    input wire valid_in, // 添加输入有效信号
    output wire valid_out, // 添加输出有效信号
    output wire y
);
    // 流水线寄存器和有效信号
    reg stage1_or;       
    reg stage1_valid;    
    reg stage2_result;   
    reg stage2_valid;    
    
    // 第一级组合逻辑：处理前两个输入
    wire first_or = a | b;
    
    // 流水线第一级
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_or <= 1'b0;
            stage1_valid <= 1'b0;
        end else begin
            stage1_or <= first_or;
            stage1_valid <= valid_in;
        end
    end
    
    // 流水线第二级
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_result <= 1'b0;
            stage2_valid <= 1'b0;
        end else begin
            stage2_result <= stage1_or | c;
            stage2_valid <= stage1_valid;
        end
    end
    
    // 输出赋值
    assign y = stage2_result;
    assign valid_out = stage2_valid;
    
endmodule