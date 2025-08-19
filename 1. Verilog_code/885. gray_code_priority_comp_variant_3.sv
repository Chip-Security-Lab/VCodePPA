//SystemVerilog
module gray_code_priority_comp #(parameter WIDTH = 8)(
    input clk, rst_n,
    input [WIDTH-1:0] data_in,
    output reg [$clog2(WIDTH)-1:0] binary_priority,
    output reg [$clog2(WIDTH)-1:0] gray_priority,
    output reg valid
);
    // Binary-to-Gray conversion function
    function [$clog2(WIDTH)-1:0] bin2gray;
        input [$clog2(WIDTH)-1:0] bin;
        begin
            bin2gray = bin ^ (bin >> 1);
        end
    endfunction
    
    // 内部信号用于跨always块通信
    reg [$clog2(WIDTH)-1:0] next_binary_priority;
    reg next_valid;
    
    // 检测输入有效性和优先级编码
    always @(*) begin
        next_valid = |data_in;
        next_binary_priority = 0;
        
        // Find highest priority bit position
        for (integer i = WIDTH-1; i >= 0; i = i - 1)
            if (data_in[i]) next_binary_priority = i[$clog2(WIDTH)-1:0];
    end
    
    // 处理二进制优先级和有效信号的寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            binary_priority <= 0;
            valid <= 0;
        end else begin
            binary_priority <= next_binary_priority;
            valid <= next_valid;
        end
    end
    
    // 处理格雷码转换和寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gray_priority <= 0;
        end else begin
            gray_priority <= bin2gray(next_binary_priority);
        end
    end
endmodule