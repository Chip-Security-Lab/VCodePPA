//SystemVerilog
module ArithEncoder #(PREC=8) (
    input clk, rst_n,
    input [7:0] data,
    output reg [PREC-1:0] code
);

    // 内部寄存器声明
    reg [PREC-1:0] low;
    reg [PREC-1:0] range;
    reg [PREC-1:0] range_scaled;
    reg [PREC-1:0] low_increment;
    
    // 补码减法相关信号
    reg [PREC-1:0] data_complement;
    reg [PREC-1:0] scaled_data;
    reg [PREC:0] sub_result; // 多一位用于处理借位
    
    // 复位逻辑处理
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            low <= 0;
            range <= 255;
        end
    end

    // 计算缩放后的范围值
    always @(posedge clk) begin
        if(rst_n) begin
            range_scaled <= range / 256 * data;
        end
    end

    // 使用二进制补码减法算法计算低位增量
    always @(posedge clk) begin
        if(rst_n) begin
            // 计算二进制表示中的 range*data/256
            scaled_data <= range*data/256;
            
            // 计算补码 (取反加一)
            data_complement <= ~(scaled_data) + 1'b1;
            
            // 执行补码减法: range + 补码(scaled_data)
            sub_result <= range + data_complement;
            
            // 结果赋值给低位增量
            low_increment <= sub_result[PREC-1:0];
        end
    end

    // 更新范围和低位值
    always @(posedge clk) begin
        if(rst_n) begin
            range <= range_scaled;
            low <= low + low_increment;
        end
    end

    // 更新输出编码
    always @(posedge clk) begin
        if(rst_n) begin
            code <= low[PREC-1:0];
        end
    end

endmodule