//SystemVerilog
module multistage_priority_comp #(parameter WIDTH = 16, STAGES = 3)(
    input clk, rst_n,
    input [WIDTH-1:0] data_in,
    output reg [$clog2(WIDTH)-1:0] priority_out
);
    // Define stage width
    localparam STAGE_WIDTH = WIDTH / STAGES;
    
    // 添加本地化参数减少扇出
    localparam CLOG2_STAGE_WIDTH = $clog2(STAGE_WIDTH);
    localparam CLOG2_STAGES = $clog2(STAGES);
    
    // 分组缓冲寄存器以减少高扇出信号
    reg [$clog2(STAGE_WIDTH)-1:0] stage_priority [0:STAGES-1];
    reg [STAGES-1:0] stage_valid;
    
    // 分布式缓冲 - 复制高扇出参数
    reg [1:0] stages_buf [0:1]; // STAGES参数缓冲
    
    // 为stage_priority和stage_valid添加缓冲寄存器
    reg [$clog2(STAGE_WIDTH)-1:0] stage_priority_buf [0:STAGES-1];
    reg [STAGES-1:0] stage_valid_buf;
    
    // 为clog2参数添加缓冲寄存器
    reg [3:0] clog2_stage_width_buf;
    reg [3:0] clog2_stages_buf;
    
    // 二进制补码减法信号 (8-bit宽度)
    reg [7:0] subtraction_input;
    reg [7:0] subtraction_result;
    reg [7:0] complement_value;
    reg carry_out;
    
    // 添加减法输入的缓冲寄存器
    reg [7:0] subtraction_input_buf1, subtraction_input_buf2;
    
    // 初始化缓冲寄存器
    initial begin
        // 分配STAGES参数的缓冲
        stages_buf[0] = STAGES[1:0];
        stages_buf[1] = STAGES[1:0];
        
        // 初始化clog2缓冲
        clog2_stage_width_buf = CLOG2_STAGE_WIDTH;
        clog2_stages_buf = CLOG2_STAGES;
    end
    
    // 二进制补码减法实现
    always @(*) begin
        complement_value = ~subtraction_input_buf2 + 8'b00000001; // 二进制补码
        subtraction_result = 8'b00000001 + complement_value; // 1 - input
        carry_out = (8'b00000001 < subtraction_input_buf2) ? 1'b0 : 1'b1;
    end
    
    // 第一级流水线 - 将输入缓存以减少负载
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            subtraction_input_buf1 <= 8'b0;
        end else begin
            subtraction_input_buf1 <= subtraction_input;
        end
    end
    
    // 第二级流水线 - 再次缓冲以均衡负载
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            subtraction_input_buf2 <= 8'b0;
        end else begin
            subtraction_input_buf2 <= subtraction_input_buf1;
        end
    end
    
    // 更新stage_valid_buf和stage_priority_buf
    always @(posedge clk) begin
        stage_valid_buf <= stage_valid;
        for (integer s = 0; s < STAGES; s = s + 1) begin
            stage_priority_buf[s] <= stage_priority[s];
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            priority_out <= 0;
            for (integer s = 0; s < STAGES; s = s + 1) begin
                stage_priority[s] <= 0;
                stage_valid[s] <= 0;
            end
        end else begin
            // 处理每个阶段
            for (integer s = 0; s < STAGES; s = s + 1) begin
                stage_valid[s] <= 0;
                stage_priority[s] <= 0;
                
                // 使用减法比较在当前段中找到优先级
                for (integer i = STAGE_WIDTH-1; i >= 0; i = i - 1) begin
                    subtraction_input = {7'b0000000, data_in[s*STAGE_WIDTH + i]};
                    if (subtraction_result[0]) begin
                        stage_valid[s] <= 1;
                        stage_priority[s] <= i[CLOG2_STAGE_WIDTH-1:0];
                    end
                end
            end
            
            // 综合结果，采用补码减法确定优先级
            priority_out <= 0;
            for (integer s = STAGES-1; s >= 0; s = s - 1) begin
                subtraction_input = {7'b0000000, stage_valid_buf[s]};
                if (subtraction_result[0])
                    priority_out <= {s[CLOG2_STAGES-1:0], 
                                   stage_priority_buf[s]};
            end
        end
    end
endmodule