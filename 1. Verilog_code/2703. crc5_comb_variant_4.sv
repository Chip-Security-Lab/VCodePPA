//SystemVerilog
module crc5_comb (
    input wire [4:0] data_in,
    input wire clk,
    input wire rst_n,
    input wire data_valid,
    input wire ready_in,  // 新增输入信号，指示下游模块是否准备好接收数据
    output reg [4:0] crc_out,
    output reg crc_valid,
    output reg ready_out  // 新增输出信号，指示当前模块是否准备好接收数据
);
    // 流水线控制信号
    reg [3:0] valid_stage; // 多级流水线valid信号
    
    // 流水线数据寄存器
    reg [4:0] data_stage1, data_stage2, data_stage3;
    reg data_msb_stage1, data_msb_stage2;
    reg [4:0] poly_mask_stage2, poly_mask_stage3;
    reg [4:0] shifted_data_stage2, shifted_data_stage3;
    
    // 计算中间结果
    wire [4:0] poly_mask_combo = data_in[4] ? 5'h15 : 5'h00;
    wire [4:0] shifted_data_combo = {data_in[3:0], 1'b0};
    
    // 流水线控制逻辑 - 处理反压和控制信号传播
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage <= 4'b0;
            ready_out <= 1'b1;
        end else begin
            // 更新流水线状态
            valid_stage[0] <= data_valid & ready_out;
            valid_stage[1] <= valid_stage[0];
            valid_stage[2] <= valid_stage[1];
            valid_stage[3] <= valid_stage[2];
            
            // 反压控制 - 只有当下游准备好接收数据，当前流水线才准备接收新数据
            ready_out <= ready_in || !valid_stage[3];
        end
    end
    
    // 第一级流水线 - 数据缓存和预计算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1 <= 5'b0;
            data_msb_stage1 <= 1'b0;
            poly_mask_stage2 <= 5'b0;
            shifted_data_stage2 <= 5'b0;
        end else if (ready_out) begin
            // 存储输入数据
            data_stage1 <= data_in;
            data_msb_stage1 <= data_in[4];
            
            // 预计算掩码和移位，减少关键路径延迟
            poly_mask_stage2 <= poly_mask_combo;
            shifted_data_stage2 <= shifted_data_combo;
        end
    end
    
    // 第二级流水线 - 中间计算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage2 <= 5'b0;
            data_msb_stage2 <= 1'b0;
            poly_mask_stage3 <= 5'b0;
            shifted_data_stage3 <= 5'b0;
        end else begin
            // 数据在流水线中传递
            data_stage2 <= data_stage1;
            data_msb_stage2 <= data_msb_stage1;
            
            // 缓存计算结果到下一级
            poly_mask_stage3 <= poly_mask_stage2;
            shifted_data_stage3 <= shifted_data_stage2;
        end
    end
    
    // 第三级流水线 - 最终CRC计算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage3 <= 5'b0;
            crc_out <= 5'b0;
            crc_valid <= 1'b0;
        end else begin
            // 数据继续传递
            data_stage3 <= data_stage2;
            
            // 最终CRC计算并输出
            crc_out <= shifted_data_stage3 ^ poly_mask_stage3;
            crc_valid <= valid_stage[2]; // 输出有效信号从流水线传递
        end
    end

endmodule