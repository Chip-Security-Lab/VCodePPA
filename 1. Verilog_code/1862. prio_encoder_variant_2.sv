//SystemVerilog
module prio_encoder #(parameter WIDTH=8) (
    input [WIDTH-1:0] data_in,
    input dir, // 0:LSB优先 1:MSB优先
    output reg [$clog2(WIDTH)-1:0] encoded,
    output reg valid
);
    reg [WIDTH-1:0] data_processed;
    reg [WIDTH-1:0] mask;
    reg [WIDTH-1:0] result;
    reg [$clog2(WIDTH)-1:0] pos;
    
    always @(*) begin
        // 初始化
        valid = |data_in;
        encoded = 0;
        
        // 根据方向处理数据
        if (dir) begin
            // MSB优先 - 反转数据
            for (int i = 0; i < WIDTH; i++) begin
                data_processed[i] = data_in[WIDTH-1-i];
            end
        end else begin
            // LSB优先 - 直接使用
            data_processed = data_in;
        end
        
        // 条件反相减法器算法
        mask = 0;
        result = data_processed;
        pos = 0;
        
        // 使用条件反相减法器查找最高优先级位
        for (int i = 0; i < WIDTH; i++) begin
            if (result[i]) begin
                pos = i;
                mask = 1 << i;
                result = result & ~mask;
            end
        end
        
        // 根据方向调整输出位置
        if (dir) begin
            encoded = WIDTH - 1 - pos;
        end else begin
            encoded = pos;
        end
    end
endmodule