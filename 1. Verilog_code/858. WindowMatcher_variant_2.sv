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
    
    // 合并所有目标模式为一个多位宽的比较值
    localparam [WIDTH*DEPTH-1:0] FULL_PATTERN = {TARGET_PATTERN_3, TARGET_PATTERN_2, TARGET_PATTERN_1, TARGET_PATTERN_0};
    
    integer i;
    // 应用后向寄存器重定时：预先寄存各个buffer位置的比较结果
    reg [WIDTH-1:0] buffer_next;
    reg match_pre;
    reg [WIDTH*DEPTH-1:0] buffer_concat, buffer_concat_next;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset buffer and match signal
            for (i = 0; i < DEPTH; i = i + 1) begin
                buffer[i] <= {WIDTH{1'b0}};
            end
            buffer_next <= {WIDTH{1'b0}};
            buffer_concat <= {(WIDTH*DEPTH){1'b0}};
            buffer_concat_next <= {(WIDTH*DEPTH){1'b0}};
            match_pre <= 1'b0;
            match <= 1'b0;
        end
        else begin
            // 提前准备下一个buffer状态
            buffer_next <= data_in;
            
            // 构建下一个周期的buffer_concat，避免在时钟上升沿后计算组合逻辑
            buffer_concat_next <= {buffer[2], buffer[1], buffer[0], buffer_next};
            
            // 移动寄存器
            for (i = DEPTH-1; i > 0; i = i - 1) begin
                buffer[i] <= buffer[i-1];
            end
            buffer[0] <= buffer_next;
            
            // 更新当前的buffer_concat
            buffer_concat <= buffer_concat_next;
            
            // 将比较结果预先寄存
            match_pre <= (buffer_concat_next == FULL_PATTERN);
            
            // 最终输出寄存器
            match <= match_pre;
        end
    end
endmodule