//SystemVerilog
module WindowMatcher #(parameter WIDTH=8, DEPTH=4) (
    input clk, rst_n,
    input [WIDTH-1:0] data_in,
    output reg match
);
    // Define a sliding window buffer to store incoming data
    reg [WIDTH-1:0] buffer [DEPTH-1:0];
    
    // 使用单独的常量替代SystemVerilog风格的数组初始化
    localparam [WIDTH-1:0] TARGET_PATTERN_0 = 8'hA1;
    localparam [WIDTH-1:0] TARGET_PATTERN_1 = 8'hB2;
    localparam [WIDTH-1:0] TARGET_PATTERN_2 = 8'hC3;
    localparam [WIDTH-1:0] TARGET_PATTERN_3 = 8'hD4;
    
    // 声明用于模式匹配检查的中间信号
    reg pattern0_match, pattern1_match, pattern2_match, pattern3_match;
    // 分层匹配信号，减少关键路径长度
    reg pattern01_match, pattern23_match;
    
    // 将数据移入缓冲区的always块
    always @(posedge clk or negedge rst_n) begin
        integer i;
        if (!rst_n) begin
            // Reset buffer
            for (i = 0; i < DEPTH; i = i + 1) begin
                buffer[i] <= {WIDTH{1'b0}};
            end
        end
        else begin
            // Shift in new data
            buffer[3] <= buffer[2];
            buffer[2] <= buffer[1];
            buffer[1] <= buffer[0];
            buffer[0] <= data_in;
        end
    end
    
    // 并行对比模式匹配
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pattern0_match <= 1'b0;
            pattern1_match <= 1'b0;
            pattern2_match <= 1'b0;
            pattern3_match <= 1'b0;
        end
        else begin
            // 预计算各位置的模式匹配结果
            pattern0_match <= (buffer[0] == TARGET_PATTERN_0);
            pattern1_match <= (buffer[1] == TARGET_PATTERN_1);
            pattern2_match <= (buffer[2] == TARGET_PATTERN_2); 
            pattern3_match <= (buffer[3] == TARGET_PATTERN_3);
        end
    end
    
    // 分层组合匹配以平衡路径延迟
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pattern01_match <= 1'b0;
            pattern23_match <= 1'b0;
            match <= 1'b0;
        end
        else begin
            // 将4输入与门拆分为2级2输入与门，减少逻辑深度
            pattern01_match <= pattern0_match & pattern1_match;
            pattern23_match <= pattern2_match & pattern3_match;
            match <= pattern01_match & pattern23_match;
        end
    end
endmodule