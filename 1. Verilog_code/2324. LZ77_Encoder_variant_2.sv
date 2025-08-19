//SystemVerilog
module LZ77_Encoder #(
    parameter WIN_SIZE = 4
) (
    input wire clk,
    input wire en,
    input wire [7:0] data,
    output reg [15:0] code
);
    // 缓冲区存储
    reg [7:0] buffer [0:WIN_SIZE-1];
    // 匹配标志
    reg match_found;
    // 匹配位置
    reg [3:0] match_position;
    
    // 借位减法器信号
    reg [WIN_SIZE:0] borrow;
    reg [WIN_SIZE-1:0] shift_direction;
    
    integer i;
    
    // 初始化
    initial begin
        match_found = 0;
        match_position = 0;
        borrow = 0;
        shift_direction = 0;
        for(i=0; i<WIN_SIZE; i=i+1)
            buffer[i] = 0;
    end
    
    // 匹配检测逻辑
    always @(posedge clk) begin
        if (en) begin
            match_found <= 0;
            match_position <= 0;
            
            for(i=0; i<WIN_SIZE; i=i+1) begin
                if(buffer[i] == data) begin
                    match_found <= 1;
                    match_position <= i[3:0];
                end
            end
        end
    end
    
    // 编码生成逻辑
    always @(posedge clk) begin
        if (en) begin
            if (match_found)
                code <= {match_position, 8'h0};
            else
                code <= 16'h0;
        end
    end
    
    // 缓冲区更新逻辑 - 使用借位减法器算法实现
    always @(posedge clk) begin
        if (en) begin
            // 初始化借位
            borrow[0] <= 0;
            
            // 使用借位减法器算法实现缓冲区移位
            for(i=0; i<WIN_SIZE-1; i=i+1) begin
                // 减法计算：buffer[i] = buffer[i-1] - 0 - borrow
                // 由于只是移位操作，所以这里简化为：
                buffer[WIN_SIZE-1-i] <= buffer[WIN_SIZE-2-i];
                
                // 在移位过程中没有实际的借位发生
                borrow[i+1] <= 0;
                
                // 记录移位方向
                shift_direction[i] <= 1;
            end
            
            // 将新数据放入缓冲区首位
            buffer[0] <= data;
        end
    end
endmodule