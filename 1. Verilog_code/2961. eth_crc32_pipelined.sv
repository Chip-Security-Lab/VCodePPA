module eth_crc32_pipelined #(
    parameter DATA_WIDTH = 8,
    parameter PIPELINE_STAGES = 2
)(
    input clk,
    input rst_n,
    input crc_en,
    input [DATA_WIDTH-1:0] data_in,
    output reg [31:0] crc_out
);
    localparam POLY = 32'h04C11DB7;
    reg [31:0] crc_stage [0:PIPELINE_STAGES-1];
    integer i, b;
    reg [31:0] new_crc;

    // 初始化流水线阶段
    initial begin
        for (i = 0; i < PIPELINE_STAGES; i = i + 1) begin
            crc_stage[i] = 32'hFFFFFFFF;
        end
        crc_out = 32'hFFFFFFFF;
    end

    // CRC流水线计算 - 展开函数为直接计算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < PIPELINE_STAGES; i = i + 1) begin
                crc_stage[i] <= 32'hFFFFFFFF;
            end
            crc_out <= 32'hFFFFFFFF;
        end else if (crc_en) begin
            // 第一个流水线阶段 - 计算next_crc
            new_crc = (PIPELINE_STAGES == 1) ? crc_out : crc_stage[PIPELINE_STAGES-1];
            
            // 按位计算CRC - 展开循环
            if (DATA_WIDTH == 8) begin
                new_crc = (new_crc << 1) ^ ((new_crc[31] ^ data_in[0]) ? POLY : 0);
                new_crc = (new_crc << 1) ^ ((new_crc[31] ^ data_in[1]) ? POLY : 0);
                new_crc = (new_crc << 1) ^ ((new_crc[31] ^ data_in[2]) ? POLY : 0);
                new_crc = (new_crc << 1) ^ ((new_crc[31] ^ data_in[3]) ? POLY : 0);
                new_crc = (new_crc << 1) ^ ((new_crc[31] ^ data_in[4]) ? POLY : 0);
                new_crc = (new_crc << 1) ^ ((new_crc[31] ^ data_in[5]) ? POLY : 0);
                new_crc = (new_crc << 1) ^ ((new_crc[31] ^ data_in[6]) ? POLY : 0);
                new_crc = (new_crc << 1) ^ ((new_crc[31] ^ data_in[7]) ? POLY : 0);
            end
            
            // 更新流水线阶段
            crc_stage[0] <= new_crc;
            
            for (i = 1; i < PIPELINE_STAGES; i = i + 1) begin
                crc_stage[i] <= crc_stage[i-1];
            end
            
            // 最终输出
            crc_out <= (PIPELINE_STAGES > 0) ? ~crc_stage[PIPELINE_STAGES-1] : ~new_crc;
        end
    end
endmodule