//SystemVerilog
module sync_rst_high #(
    parameter DATA_WIDTH = 8,
    parameter PIPELINE_STAGES = 3
) (
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  en,
    input  wire [DATA_WIDTH-1:0] data_in,
    output wire [DATA_WIDTH-1:0] data_out
);
    // 声明流水线寄存器组和有效信号组
    reg [DATA_WIDTH-1:0] data_pipe [0:PIPELINE_STAGES-1];
    reg [PIPELINE_STAGES-1:0] valid_pipe;
    
    // 生成流水线级
    genvar i;
    generate
        // 第一级流水线（特殊处理输入）
        always @(posedge clk) begin
            if (!rst_n) begin
                data_pipe[0] <= {DATA_WIDTH{1'b0}};
                valid_pipe[0] <= 1'b0;
            end else begin
                valid_pipe[0] <= en;
                if (en) data_pipe[0] <= data_in;
            end
        end
        
        // 生成后续流水线级
        for (i = 1; i < PIPELINE_STAGES; i = i + 1) begin : pipe_stages
            always @(posedge clk) begin
                if (!rst_n) begin
                    data_pipe[i] <= {DATA_WIDTH{1'b0}};
                    valid_pipe[i] <= 1'b0;
                end else begin
                    valid_pipe[i] <= valid_pipe[i-1];
                    // 只有前一级有效时才更新数据，减少功耗
                    if (valid_pipe[i-1]) data_pipe[i] <= data_pipe[i-1];
                end
            end
        end
    endgenerate
    
    // 模块输出
    assign data_out = data_pipe[PIPELINE_STAGES-1];
    
endmodule