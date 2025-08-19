//SystemVerilog
module shift_reg_barrel_shifter #(
    parameter WIDTH = 16
)(
    input                       clk,
    input                       rst_n,       // 添加复位信号
    input                       valid_in,    // 输入有效信号
    output                      ready_in,    // 输入就绪信号
    input      [WIDTH-1:0]      data_in,
    input      [$clog2(WIDTH)-1:0] shift_amount,
    output     [WIDTH-1:0]      data_out,
    output                      valid_out,   // 输出有效信号
    input                       ready_out    // 输出就绪信号
);
    // 定义位移位数为常量
    localparam LOG2_WIDTH = $clog2(WIDTH);
    
    // 流水线级数
    localparam PIPELINE_STAGES = LOG2_WIDTH + 1;
    
    // 流水线阶段寄存器
    reg [WIDTH-1:0] stage_data [0:PIPELINE_STAGES-1];
    reg [$clog2(WIDTH)-1:0] stage_shift [0:PIPELINE_STAGES-2];
    
    // 流水线控制信号
    reg [PIPELINE_STAGES-1:0] stage_valid;
    wire [PIPELINE_STAGES-1:0] stage_ready;
    
    // 确定stage_ready信号 - 反向传播
    assign stage_ready[PIPELINE_STAGES-1] = ready_out;
    
    genvar i;
    generate
        for (i = PIPELINE_STAGES-2; i >= 0; i = i - 1) begin : ready_chain
            assign stage_ready[i] = stage_ready[i+1] || !stage_valid[i+1];
        end
    endgenerate
    
    // 输入接口控制
    assign ready_in = stage_ready[0];
    
    // 输出接口控制
    assign valid_out = stage_valid[PIPELINE_STAGES-1];
    assign data_out = stage_data[PIPELINE_STAGES-1];
    
    // 流水线第一级 - 输入级
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage_valid[0] <= 1'b0;
            stage_data[0] <= {WIDTH{1'b0}};
            stage_shift[0] <= {LOG2_WIDTH{1'b0}};
        end else if (valid_in && ready_in) begin
            stage_valid[0] <= 1'b1;
            stage_data[0] <= data_in;
            stage_shift[0] <= shift_amount;
        end else if (stage_ready[0]) begin
            stage_valid[0] <= 1'b0;
        end
    end
    
    // 生成流水线阶段
    generate 
        for (i = 0; i < LOG2_WIDTH; i = i + 1) begin : pipeline_stages
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    stage_valid[i+1] <= 1'b0;
                    stage_data[i+1] <= {WIDTH{1'b0}};
                    if (i < LOG2_WIDTH-1)
                        stage_shift[i+1] <= {LOG2_WIDTH{1'b0}};
                end else if (stage_valid[i] && stage_ready[i]) begin
                    stage_valid[i+1] <= 1'b1;
                    
                    // 执行当前移位操作
                    if (i == 0) begin
                        stage_data[i+1] <= stage_shift[i][0] ? 
                                          {stage_data[i][WIDTH-2:0], 1'b0} : 
                                          stage_data[i];
                    end else if (i == 1) begin
                        stage_data[i+1] <= stage_shift[i][1] ? 
                                          {stage_data[i][WIDTH-3:0], 2'b0} : 
                                          stage_data[i];
                    end else if (i == 2) begin
                        stage_data[i+1] <= stage_shift[i][2] ? 
                                          {stage_data[i][WIDTH-5:0], 4'b0} : 
                                          stage_data[i];
                    end else if (i == 3) begin
                        stage_data[i+1] <= stage_shift[i][3] ? 
                                          {stage_data[i][WIDTH-9:0], 8'b0} : 
                                          stage_data[i];
                    end else if (i == 4) begin
                        stage_data[i+1] <= stage_shift[i][4] ? 
                                          {stage_data[i][WIDTH-17:0], 16'b0} : 
                                          stage_data[i];
                    end
                    
                    // 传递移位控制信号到下一级
                    if (i < LOG2_WIDTH-1)
                        stage_shift[i+1] <= stage_shift[i];
                end else if (stage_ready[i+1]) begin
                    stage_valid[i+1] <= 1'b0;
                end
            end
        end
    endgenerate
    
endmodule