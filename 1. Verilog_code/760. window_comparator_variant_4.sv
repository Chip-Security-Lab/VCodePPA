//SystemVerilog
module window_comparator(
    input wire clk,              
    input wire rst_n,            
    input wire [11:0] data_value,
    input wire [11:0] lower_bound,
    input wire [11:0] upper_bound,
    output reg in_range,         
    output reg out_of_range,     
    output reg at_boundary       
);
    // Stage 1: 输入寄存器
    reg [11:0] data_value_r, lower_bound_r, upper_bound_r;
    
    // Stage 2: 比较结果寄存器
    reg below_lower_r, above_upper_r, equal_lower_r, equal_upper_r;
    
    // 第一级流水线：寄存输入值 - 扁平化if-else结构
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_value_r <= 12'b0;
            lower_bound_r <= 12'b0;
            upper_bound_r <= 12'b0;
        end else begin
            data_value_r <= data_value;
            lower_bound_r <= lower_bound;
            upper_bound_r <= upper_bound;
        end
    end
    
    // 第二级流水线：计算比较结果并寄存 - 扁平化if-else结构
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            below_lower_r <= 1'b0;
            above_upper_r <= 1'b0;
            equal_lower_r <= 1'b0;
            equal_upper_r <= 1'b0;
        end else begin
            below_lower_r <= (data_value_r < lower_bound_r);
            above_upper_r <= (data_value_r > upper_bound_r);
            equal_lower_r <= (data_value_r == lower_bound_r);
            equal_upper_r <= (data_value_r == upper_bound_r);
        end
    end
    
    // 第三级流水线：组合比较结果生成最终输出 - 扁平化if-else结构
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in_range <= 1'b0;
            out_of_range <= 1'b0;
            at_boundary <= 1'b0;
        end else if (equal_lower_r || equal_upper_r) begin
            in_range <= 1'b1;
            out_of_range <= 1'b0;
            at_boundary <= 1'b1;
        end else if (below_lower_r || above_upper_r) begin
            in_range <= 1'b0;
            out_of_range <= 1'b1;
            at_boundary <= 1'b0;
        end else begin
            in_range <= 1'b1;
            out_of_range <= 1'b0;
            at_boundary <= 1'b0;
        end
    end
endmodule