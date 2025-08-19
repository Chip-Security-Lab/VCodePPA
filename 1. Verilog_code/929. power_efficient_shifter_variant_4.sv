//SystemVerilog
module power_efficient_shifter(
    input clk,
    input rst,           // 添加复位信号
    input req,           // 请求信号
    input [7:0] data_in,
    input [2:0] shift,
    output reg [7:0] data_out,
    output reg ack       // 应答信号
);
    // 流水线寄存器和控制信号
    reg [7:0] data_stage1, data_stage2;
    reg [2:0] shift_stage1, shift_stage2;
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // 功率控制信号
    wire active_stage1, active_stage2, active_stage3;
    
    // 计算每个阶段是否激活
    assign active_stage1 = valid_stage1 & |shift_stage1;
    assign active_stage2 = valid_stage2 & |shift_stage1[2:1];
    assign active_stage3 = valid_stage3 & shift_stage2[2];
    
    // 第一级流水线 - 输入寄存
    always @(posedge clk) begin
        if (rst) begin
            valid_stage1 <= 1'b0;
            data_stage1 <= 8'h0;
            shift_stage1 <= 3'h0;
        end else if (req) begin
            valid_stage1 <= 1'b1;
            data_stage1 <= data_in;
            shift_stage1 <= shift;
        end else if (!req && valid_stage3) begin
            // 完成操作后重置
            valid_stage1 <= 1'b0;
        end
    end
    
    // 第二级流水线 - 第一次移位操作 (1位移位)
    always @(posedge clk) begin
        if (rst) begin
            valid_stage2 <= 1'b0;
            data_stage2 <= 8'h0;
            shift_stage2 <= 3'h0;
        end else if (valid_stage1) begin
            valid_stage2 <= 1'b1;
            shift_stage2 <= shift_stage1;
            
            if (shift_stage1[0] && active_stage1)
                data_stage2 <= {data_stage1[6:0], 1'b0};
            else
                data_stage2 <= data_stage1;
        end else if (!valid_stage1 && valid_stage3) begin
            valid_stage2 <= 1'b0;
        end
    end
    
    // 第三级流水线 - 第二、三次移位 (2位和4位移位)
    always @(posedge clk) begin
        if (rst) begin
            valid_stage3 <= 1'b0;
            data_out <= 8'h0;
            ack <= 1'b0;
        end else if (valid_stage2) begin
            valid_stage3 <= 1'b1;
            
            // 2位移位
            if (shift_stage2[1] && active_stage2)
                data_out <= {data_stage2[5:0], 2'b0};
            else
                data_out <= data_stage2;
                
            // 4位移位
            if (shift_stage2[2] && active_stage3)
                data_out <= {data_out[3:0], 4'b0};
                
            // 生成应答信号
            ack <= 1'b1;
        end else if (!valid_stage2 && valid_stage3) begin
            valid_stage3 <= 1'b0;
            ack <= 1'b0;
        end
    end
endmodule