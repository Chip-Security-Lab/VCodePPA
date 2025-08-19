//SystemVerilog
module crc_adaptive #(
    parameter MAX_WIDTH = 64
)(
    input wire clk,
    input wire rst_n,  // 添加复位信号提高稳定性
    input wire [MAX_WIDTH-1:0] data,
    input wire [5:0] width_sel,
    output reg [31:0] crc
);
    // 流水线级数定义
    localparam PIPELINE_STAGES = 4;
    localparam BITS_PER_STAGE = (MAX_WIDTH + PIPELINE_STAGES - 1) / PIPELINE_STAGES;
    
    // 分段处理寄存器
    reg [31:0] crc_stage[0:PIPELINE_STAGES];
    reg [MAX_WIDTH-1:0] data_stage[0:PIPELINE_STAGES-1];
    reg [5:0] width_rem[0:PIPELINE_STAGES-1];
    
    // 分段计算标志
    wire [PIPELINE_STAGES-1:0] stage_valid;
    
    // 常量定义：CRC多项式
    localparam CRC_POLY = 32'h04C11DB7;
    
    // 单位计算函数
    function [31:0] calc_crc_bit;
        input [31:0] crc_in;
        input data_bit;
        begin
            calc_crc_bit = {crc_in[30:0], 1'b0} ^ 
                          ((crc_in[31] ^ data_bit) ? CRC_POLY : 32'h0);
        end
    endfunction
    
    integer j;
    genvar g;
    
    // 初始化阶段 - 输入注册
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage[0] <= {MAX_WIDTH{1'b0}};
            width_rem[0] <= 6'd0;
            crc_stage[0] <= 32'hFFFFFFFF; // 初始值
        end else begin
            data_stage[0] <= data;
            width_rem[0] <= width_sel;
            crc_stage[0] <= crc;
        end
    end
    
    // 生成流水线阶段
    generate
        for (g = 0; g < PIPELINE_STAGES; g = g + 1) begin : pipeline_stage
            assign stage_valid[g] = (g == 0) ? 1'b1 : (width_rem[g-1] > 0);
            
            // 计算每个阶段的CRC
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    if (g < PIPELINE_STAGES-1) begin
                        data_stage[g+1] <= {MAX_WIDTH{1'b0}};
                        width_rem[g+1] <= 6'd0;
                    end
                    crc_stage[g+1] <= 32'hFFFFFFFF;
                end else begin
                    if (stage_valid[g]) begin
                        // 处理本阶段分配的比特
                        reg [31:0] temp_crc;
                        temp_crc = crc_stage[g];
                        
                        for (j = 0; j < BITS_PER_STAGE; j = j + 1) begin
                            if (g*BITS_PER_STAGE + j < width_rem[g]) begin
                                temp_crc = calc_crc_bit(temp_crc, data_stage[g][j]);
                            end
                        end
                        
                        crc_stage[g+1] <= temp_crc;
                        
                        if (g < PIPELINE_STAGES-1) begin
                            // 准备下一阶段的数据
                            data_stage[g+1] <= {data_stage[g][BITS_PER_STAGE+:MAX_WIDTH-BITS_PER_STAGE], {BITS_PER_STAGE{1'b0}}};
                            width_rem[g+1] <= (width_rem[g] > BITS_PER_STAGE) ? (width_rem[g] - BITS_PER_STAGE) : 6'd0;
                        end
                    end else begin
                        if (g < PIPELINE_STAGES-1) begin
                            data_stage[g+1] <= data_stage[g];
                            width_rem[g+1] <= width_rem[g];
                        end
                        crc_stage[g+1] <= crc_stage[g];
                    end
                end
            end
        end
    endgenerate
    
    // 最终输出赋值
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc <= 32'hFFFFFFFF;
        end else begin
            crc <= crc_stage[PIPELINE_STAGES];
        end
    end
    
endmodule