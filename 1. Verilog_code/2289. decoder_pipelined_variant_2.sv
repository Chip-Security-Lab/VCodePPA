//SystemVerilog
module decoder_pipelined (
    input logic clk,
    input logic rst_n,  // 添加复位信号
    input logic valid_in,  // 输入有效信号
    input logic [3:0] addr,
    output logic valid_out,  // 输出有效信号
    output logic [15:0] decoded
);
    // 第一阶段 - 地址处理
    logic [3:0] addr_stage1;
    logic valid_stage1;
    
    // 第二阶段 - 低位解码
    logic [7:0] low_decoded_stage2;
    logic [3:0] addr_high_stage2;
    logic valid_stage2;
    
    // 第三阶段 - 高位选择和完整解码
    logic [15:0] decoded_stage3;
    logic valid_stage3;
    
    // 第一级流水线 - 地址缓存
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage1 <= 4'b0;
            valid_stage1 <= 1'b0;
        end else begin
            addr_stage1 <= addr;
            valid_stage1 <= valid_in;
        end
    end
    
    // 第二级流水线 - 低位解码
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            low_decoded_stage2 <= 8'b0;
            addr_high_stage2 <= 2'b0;
            valid_stage2 <= 1'b0;
        end else begin
            // 解码低3位
            low_decoded_stage2 <= 1'b1 << addr_stage1[2:0];
            addr_high_stage2 <= {2'b0, addr_stage1[3]};
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 第三级流水线 - 高位选择和完整解码
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            decoded_stage3 <= 16'b0;
            valid_stage3 <= 1'b0;
        end else begin
            // 基于高位选择输出
            if (addr_high_stage2[0]) 
                decoded_stage3 <= {low_decoded_stage2, 8'b0};
            else
                decoded_stage3 <= {8'b0, low_decoded_stage2};
            valid_stage3 <= valid_stage2;
        end
    end
    
    // 输出寄存器
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            decoded <= 16'b0;
            valid_out <= 1'b0;
        end else begin
            decoded <= decoded_stage3;
            valid_out <= valid_stage3;
        end
    end
endmodule