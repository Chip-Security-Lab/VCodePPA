//SystemVerilog
module crc16_with_valid(
    input clk,
    input reset,
    input [7:0] data_in,
    input data_valid,
    output reg [15:0] crc,
    output reg crc_valid
);
    localparam POLY = 16'h1021;
    
    // 流水线阶段1: 初始CRC处理
    reg [15:0] crc_stage1;
    reg [7:0] data_stage1;
    reg valid_stage1;
    
    // 流水线阶段2: 多项式异或计算
    reg [15:0] crc_stage2;
    reg valid_stage2;
    
    // 流水线阶段3: 最终结果计算
    reg [15:0] crc_stage3;
    reg valid_stage3;
    
    // 阶段1: 接收输入并准备初始计算
    always @(posedge clk) begin
        if (reset) begin
            crc_stage1 <= 16'hFFFF;
            data_stage1 <= 8'h00;
            valid_stage1 <= 1'b0;
        end else begin
            if (data_valid) begin
                crc_stage1 <= crc;
                data_stage1 <= data_in;
                valid_stage1 <= 1'b1;
            end else begin
                valid_stage1 <= 1'b0;
            end
        end
    end
    
    // 阶段2: 执行第一部分CRC计算 (左移和检查MSB)
    always @(posedge clk) begin
        if (reset) begin
            crc_stage2 <= 16'h0000;
            valid_stage2 <= 1'b0;
        end else begin
            if (valid_stage1) begin
                crc_stage2 <= {crc_stage1[14:0], 1'b0};
                valid_stage2 <= 1'b1;
            end else begin
                valid_stage2 <= 1'b0;
            end
        end
    end
    
    // 阶段3: 执行多项式异或和数据异或操作
    always @(posedge clk) begin
        if (reset) begin
            crc_stage3 <= 16'h0000;
            valid_stage3 <= 1'b0;
        end else begin
            if (valid_stage2) begin
                crc_stage3 <= crc_stage2 ^ (crc_stage1[15] ? POLY : 16'h0000) ^ {8'h00, data_stage1};
                valid_stage3 <= 1'b1;
            end else begin
                valid_stage3 <= 1'b0;
            end
        end
    end
    
    // 最终输出阶段
    always @(posedge clk) begin
        if (reset) begin
            crc <= 16'hFFFF;
            crc_valid <= 1'b0;
        end else begin
            if (valid_stage3) begin
                crc <= crc_stage3;
                crc_valid <= 1'b1;
            end else begin
                crc_valid <= 1'b0;
            end
        end
    end
    
endmodule