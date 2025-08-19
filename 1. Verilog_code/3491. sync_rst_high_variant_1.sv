//SystemVerilog
module sync_rst_high #(parameter DATA_WIDTH=8, parameter PIPELINE_STAGES=3) (
    input wire clk,
    input wire rst_n,
    input wire en,
    input wire [DATA_WIDTH-1:0] data_in,
    output wire [DATA_WIDTH-1:0] data_out
);
    // 定义流水线寄存器
    reg [DATA_WIDTH-1:0] stage_data [PIPELINE_STAGES-1:0];
    reg [PIPELINE_STAGES-1:0] stage_valid;
    
    // 使用参数化常量提高可维护性
    localparam HALF_WIDTH = DATA_WIDTH/2;
    
    // 优化：将输入数据预处理，采用并行处理结构
    reg [HALF_WIDTH-1:0] data_in_lower_reg, data_in_upper_reg;
    
    // 优化：采用单时钟域设计，减少时序约束复杂度
    always @(posedge clk) begin
        if (!rst_n) begin
            data_in_lower_reg <= {HALF_WIDTH{1'b0}};
            data_in_upper_reg <= {HALF_WIDTH{1'b0}};
        end
        else if (en) begin  // 添加使能条件，减少功耗
            data_in_lower_reg <= data_in[HALF_WIDTH-1:0];
            data_in_upper_reg <= data_in[DATA_WIDTH-1:HALF_WIDTH];
        end
    end
    
    // 优化：第一级流水线，减少逻辑路径
    always @(posedge clk) begin
        if (!rst_n) begin
            stage_data[0] <= {DATA_WIDTH{1'b0}};
            stage_valid[0] <= 1'b0;
        end
        else if (en) begin
            stage_data[0] <= {data_in_upper_reg, data_in_lower_reg};
            stage_valid[0] <= 1'b1;
        end
        else begin
            stage_valid[0] <= 1'b0;
        end
    end
    
    // 优化：减少流水线级间的依赖关系，将临时缓存整合到主流水线中
    genvar i;
    generate
        for (i = 1; i < PIPELINE_STAGES; i = i + 1) begin : pipeline_stage
            always @(posedge clk) begin
                if (!rst_n) begin
                    stage_data[i] <= {DATA_WIDTH{1'b0}};
                    stage_valid[i] <= 1'b0;
                end
                else if (stage_valid[i-1]) begin
                    stage_data[i] <= stage_data[i-1];
                    stage_valid[i] <= 1'b1;
                end
                else begin
                    stage_valid[i] <= 1'b0;
                end
            end
        end
    endgenerate
    
    // 优化：采用寄存器化输出设计，提高时序稳定性
    reg [DATA_WIDTH-1:0] data_out_reg;
    
    always @(posedge clk) begin
        if (!rst_n) begin
            data_out_reg <= {DATA_WIDTH{1'b0}};
        end
        else if (stage_valid[PIPELINE_STAGES-1]) begin
            data_out_reg <= stage_data[PIPELINE_STAGES-1];
        end
    end
    
    // 输出赋值
    assign data_out = data_out_reg;
    
endmodule