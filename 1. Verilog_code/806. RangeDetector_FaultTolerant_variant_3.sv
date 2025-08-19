//SystemVerilog
module RangeDetector_FaultTolerant #(
    parameter WIDTH = 8,
    parameter TOLERANCE = 3
)(
    input clk, rst_n,
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] low_th,
    input [WIDTH-1:0] high_th,
    input valid_in,               // 输入数据有效信号
    output ready_in,              // 输入就绪信号
    output reg alarm,
    output reg valid_out          // 输出有效信号
);
    // 流水线控制信号
    reg valid_stage1, valid_stage2;
    wire ready_stage1, ready_stage2;
    
    // 第一级流水线寄存器
    reg [WIDTH-1:0] data_stage1;
    reg [WIDTH-1:0] low_th_stage1;
    reg [WIDTH-1:0] high_th_stage1;
    reg out_of_range_stage1;
    
    // 第二级流水线寄存器
    reg [1:0] err_count_stage2;
    reg out_of_range_stage2;
    
    // 反压控制信号
    assign ready_in = rst_n && (ready_stage1 || !valid_stage1);
    assign ready_stage1 = rst_n && (ready_stage2 || !valid_stage2);
    assign ready_stage2 = 1'b1; // 最后一级总是就绪
    
    // 第一级流水线：范围检测
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            data_stage1 <= 0;
            low_th_stage1 <= 0;
            high_th_stage1 <= 0;
            out_of_range_stage1 <= 0;
            valid_stage1 <= 0;
        end
        else if(ready_stage1) begin
            if(valid_in && ready_in) begin
                // 捕获输入数据
                data_stage1 <= data_in;
                low_th_stage1 <= low_th;
                high_th_stage1 <= high_th;
                // 执行范围检测计算
                out_of_range_stage1 <= (data_in < low_th || data_in > high_th);
                valid_stage1 <= 1'b1;
            end 
            else begin
                valid_stage1 <= 1'b0;
            end
        end
    end
    
    // 第二级流水线：容错计数逻辑
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            err_count_stage2 <= 0;
            out_of_range_stage2 <= 0;
            valid_stage2 <= 0;
        end
        else if(ready_stage2) begin
            if(valid_stage1 && ready_stage1) begin
                // 传递范围检测结果
                out_of_range_stage2 <= out_of_range_stage1;
                
                // 计算错误计数
                if(out_of_range_stage1) begin
                    err_count_stage2 <= (err_count_stage2 < TOLERANCE) ? 
                                        err_count_stage2 + 1 : TOLERANCE;
                end
                else begin
                    err_count_stage2 <= (err_count_stage2 > 0) ? 
                                        err_count_stage2 - 1 : 0;
                end
                
                valid_stage2 <= 1'b1;
            end
            else begin
                valid_stage2 <= 1'b0;
            end
        end
    end
    
    // 输出级：报警生成
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            alarm <= 0;
            valid_out <= 0;
        end
        else begin
            if(valid_stage2) begin
                alarm <= (err_count_stage2 == TOLERANCE);
                valid_out <= 1'b1;
            end
            else begin
                valid_out <= 1'b0;
            end
        end
    end
endmodule