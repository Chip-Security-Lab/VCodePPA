//SystemVerilog IEEE 1364-2005
module pipeline_sync_rst #(
    parameter WIDTH = 8,
    parameter STAGES = 4  // 增加了流水线级数参数
)(
    input  wire              clk,
    input  wire              rst,
    input  wire              valid_in,
    input  wire [WIDTH-1:0]  din,
    output wire              valid_out,
    output wire [WIDTH-1:0]  dout,
    input  wire              ready_in,
    output wire              ready_out
);
    // 流水线数据和控制信号
    reg [WIDTH-1:0] stage_data [STAGES-1:0];
    reg             stage_valid[STAGES-1:0];
    wire            stage_ready[STAGES-1:0];
    
    // 输出赋值
    assign valid_out = stage_valid[STAGES-1];
    assign dout = stage_data[STAGES-1];
    
    // 流水线就绪信号逻辑 - 反压机制
    assign stage_ready[STAGES-1] = ready_in;
    
    genvar i;
    generate
        for (i = STAGES-2; i >= 0; i = i - 1) begin : ready_logic
            assign stage_ready[i] = !stage_valid[i+1] || stage_ready[i+1];
        end
    endgenerate
    
    // 输入就绪信号
    assign ready_out = stage_ready[0];
    
    // 第一级流水线 - 特殊处理输入
    always @(posedge clk) begin
        if (rst) begin
            stage_data[0] <= {WIDTH{1'b0}};
            stage_valid[0] <= 1'b0;
        end 
        else if (stage_ready[0]) begin
            stage_data[0] <= din;
            stage_valid[0] <= valid_in;
        end
    end
    
    // 剩余流水线级
    generate
        for (i = 1; i < STAGES; i = i + 1) begin : pipeline_stage
            always @(posedge clk) begin
                if (rst) begin
                    stage_data[i] <= {WIDTH{1'b0}};
                    stage_valid[i] <= 1'b0;
                end 
                else if (stage_ready[i]) begin
                    // 模拟每级的处理逻辑 - 可以根据实际需求修改
                    if (i == 1) begin
                        // 第二级: 数据处理示例 - 位翻转
                        stage_data[i] <= {stage_data[i-1][0], stage_data[i-1][WIDTH-1:1]};
                    end
                    else if (i == 2) begin
                        // 第三级: 数据处理示例 - 奇偶位交换
                        for (int j = 0; j < WIDTH/2; j = j + 1) begin
                            stage_data[i][j*2] <= stage_data[i-1][j*2+1];
                            stage_data[i][j*2+1] <= stage_data[i-1][j*2];
                        end
                    end
                    else begin
                        // 其他级: 直接传递
                        stage_data[i] <= stage_data[i-1];
                    end
                    stage_valid[i] <= stage_valid[i-1];
                end
            end
        end
    endgenerate

    // 流水线性能计数器 (用于分析和调试)
    reg [31:0] throughput_counter;
    reg [31:0] stall_counter;
    
    always @(posedge clk) begin
        if (rst) begin
            throughput_counter <= 32'd0;
            stall_counter <= 32'd0;
        end
        else begin
            if (valid_out && ready_in)
                throughput_counter <= throughput_counter + 1;
            
            if (!ready_out && valid_in)
                stall_counter <= stall_counter + 1;
        end
    end
    
endmodule