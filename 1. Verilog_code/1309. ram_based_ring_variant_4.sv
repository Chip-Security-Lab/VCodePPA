//SystemVerilog
module ram_based_ring #(parameter ADDR_WIDTH=4) (
    input clk, rst,
    output reg [2**ADDR_WIDTH-1:0] ram_out
);
    // 流水线阶段定义和控制信号
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // 地址计数器和缓冲
    reg [ADDR_WIDTH-1:0] addr_stage1;
    reg [ADDR_WIDTH-1:0] addr_stage2;
    
    // 数据流水线寄存器
    reg [2**ADDR_WIDTH-1:0] ram_data_stage1;
    reg [2**ADDR_WIDTH-1:0] ram_data_stage2;
    reg [2**ADDR_WIDTH-1:0] ram_data_stage3;
    
    // 分段处理高低位数据
    reg [2**ADDR_WIDTH/2-1:0] ram_high_stage2, ram_high_stage3;
    reg [2**ADDR_WIDTH/2-1:0] ram_low_stage2, ram_low_stage3;
    
    // 复位信号流水线缓冲
    reg rst_buf1, rst_buf2, rst_buf3;
    
    // 第一级流水线：复位缓冲和地址计算
    always @(posedge clk) begin
        // 复位信号缓冲链
        rst_buf1 <= rst;
        rst_buf2 <= rst_buf1;
        rst_buf3 <= rst_buf2;
        
        // 第一级流水线控制
        if (rst_buf1) begin
            valid_stage1 <= 1'b0;
            addr_stage1 <= 0;
        end else begin
            valid_stage1 <= 1'b1;
            addr_stage1 <= addr_stage1 + 1;
        end
    end
    
    // 第二级流水线：位移计算和数据准备
    always @(posedge clk) begin
        if (rst_buf2) begin
            valid_stage2 <= 1'b0;
            ram_data_stage1 <= {{(2**ADDR_WIDTH-1){1'b0}}, 1'b1}; // 初始化为仅LSB为1
        end else begin
            valid_stage2 <= valid_stage1;
            addr_stage2 <= addr_stage1;
            
            // 通过位移计算下一状态
            ram_data_stage1 <= {ram_out[0], ram_out[2**ADDR_WIDTH-1:1]};
            
            // 分离高低位进行处理
            ram_high_stage2 <= ram_data_stage1[2**ADDR_WIDTH-1:2**ADDR_WIDTH/2];
            ram_low_stage2 <= ram_data_stage1[2**ADDR_WIDTH/2-1:0];
        end
    end
    
    // 第三级流水线：数据组合与最终处理
    always @(posedge clk) begin
        if (rst_buf3) begin
            valid_stage3 <= 1'b0;
            ram_high_stage3 <= {(2**ADDR_WIDTH/2){1'b0}};
            ram_low_stage3 <= {{(2**ADDR_WIDTH/2-1){1'b0}}, 1'b1};
        end else begin
            valid_stage3 <= valid_stage2;
            
            // 传递处理后的高低位数据
            ram_high_stage3 <= ram_high_stage2;
            ram_low_stage3 <= ram_low_stage2;
            
            // 最终数据组合
            if (valid_stage3) begin
                ram_out[2**ADDR_WIDTH-1:2**ADDR_WIDTH/2] <= ram_high_stage3;
                ram_out[2**ADDR_WIDTH/2-1:0] <= ram_low_stage3;
            end
        end
    end
    
endmodule