//SystemVerilog
module AsymCompress #(
    parameter IN_W  = 64,
    parameter OUT_W = 32,
    parameter STAGES = 2  // 流水线级数，可以根据IN_W/OUT_W调整
)(
    input  wire clk,          // 时钟输入用于流水线
    input  wire rst_n,        // 复位信号
    input  wire [IN_W-1:0] din,
    input  wire din_valid,    // 输入有效信号
    output wire [OUT_W-1:0] dout,
    output wire dout_valid    // 输出有效信号
);

    // 定义内部信号
    reg [OUT_W-1:0] compression_stages[0:STAGES-1];
    reg [STAGES-1:0] valid_pipeline;
    
    // 计算一个阶段要处理的块数
    localparam BLOCKS_PER_STAGE = (IN_W/OUT_W + STAGES - 1) / STAGES;
    localparam TOTAL_BLOCKS = IN_W/OUT_W;
    
    // 针对大型输入数据和XOR树创建中间结果寄存器
    reg [OUT_W-1:0] xor_intermediate[0:STAGES-1][0:BLOCKS_PER_STAGE-1];
    reg [OUT_W-1:0] stage_result[0:STAGES-1];
    
    // 输入数据缓存以减少扇出负载
    reg [IN_W-1:0] din_reg;
    reg din_valid_reg;
    
    // 输入数据缓存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            din_reg <= {IN_W{1'b0}};
            din_valid_reg <= 1'b0;
        end else begin
            din_reg <= din;
            din_valid_reg <= din_valid;
        end
    end
    
    integer i, j, block_idx;
    
    // 第一级 - 计算各块的XOR中间结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < BLOCKS_PER_STAGE; i = i + 1) begin
                xor_intermediate[0][i] <= {OUT_W{1'b0}};
            end
            valid_pipeline[0] <= 1'b0;
        end else begin
            valid_pipeline[0] <= din_valid_reg;
            
            if (din_valid_reg) begin
                for (j = 0; j < BLOCKS_PER_STAGE && j < TOTAL_BLOCKS; j = j + 1) begin
                    xor_intermediate[0][j] <= din_reg[j*OUT_W +: OUT_W];
                end
            end
        end
    end
    
    // 第一级 - 合并各块XOR结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            compression_stages[0] <= {OUT_W{1'b0}};
        end else if (valid_pipeline[0]) begin
            compression_stages[0] <= {OUT_W{1'b0}};
            for (j = 0; j < BLOCKS_PER_STAGE && j < TOTAL_BLOCKS; j = j + 1) begin
                compression_stages[0] <= compression_stages[0] ^ xor_intermediate[0][j];
            end
        end
    end
    
    // 后续流水线级 - 两阶段：先读取和存储，然后合并
    genvar stage;
    generate
        for (stage = 1; stage < STAGES; stage = stage + 1) begin : pipeline_stages
            // 第一阶段：读取输入块
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    for (i = 0; i < BLOCKS_PER_STAGE; i = i + 1) begin
                        xor_intermediate[stage][i] <= {OUT_W{1'b0}};
                    end
                    valid_pipeline[stage] <= 1'b0;
                end else begin
                    valid_pipeline[stage] <= valid_pipeline[stage-1];
                    
                    if (valid_pipeline[stage-1]) begin
                        for (j = 0; j < BLOCKS_PER_STAGE && 
                             (stage*BLOCKS_PER_STAGE + j) < TOTAL_BLOCKS; j = j + 1) begin
                            block_idx = stage*BLOCKS_PER_STAGE + j;
                            xor_intermediate[stage][j] <= din_reg[block_idx*OUT_W +: OUT_W];
                        end
                    end
                end
            end
            
            // 第二阶段：合并结果
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    compression_stages[stage] <= {OUT_W{1'b0}};
                end else if (valid_pipeline[stage]) begin
                    compression_stages[stage] <= compression_stages[stage-1];
                    for (j = 0; j < BLOCKS_PER_STAGE && 
                         (stage*BLOCKS_PER_STAGE + j) < TOTAL_BLOCKS; j = j + 1) begin
                        compression_stages[stage] <= compression_stages[stage] ^ 
                                                    xor_intermediate[stage][j];
                    end
                end
            end
        end
    endgenerate
    
    // 增加输出寄存器以改善时序
    reg [OUT_W-1:0] dout_reg;
    reg dout_valid_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dout_reg <= {OUT_W{1'b0}};
            dout_valid_reg <= 1'b0;
        end else begin
            dout_reg <= compression_stages[STAGES-1];
            dout_valid_reg <= valid_pipeline[STAGES-1];
        end
    end
    
    // 输出赋值
    assign dout = dout_reg;
    assign dout_valid = dout_valid_reg;

endmodule