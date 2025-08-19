//SystemVerilog
module WindowMax #(parameter W=8, MAX_WIN=5) (
    input clk,
    input [3:0] win_size,
    input [W-1:0] din,
    output reg [W-1:0] max_val
);
    reg [W-1:0] buffer [0:MAX_WIN-1];
    reg [W-1:0] temp_max;
    integer i;
    
    // 使用二进制补码比较两个数值的大小
    function automatic [W-1:0] comp_max;
        input [W-1:0] a, b;
        reg [W:0] diff; // 额外一位用于符号位
        begin
            // 使用二进制补码算法：a-b，如果差值为负（最高位为1），则b更大
            diff = {1'b0, a} - {1'b0, b};
            comp_max = diff[W] ? b : a; // 检查符号位
        end
    endfunction
    
    always @(posedge clk) begin
        // 手动移位缓冲区
        for(i=MAX_WIN-1; i>0; i=i-1)
            buffer[i] <= buffer[i-1];
        buffer[0] <= din;
        
        // 查找最大值，使用二进制补码比较
        temp_max = buffer[0];
        for(i=1; i<MAX_WIN; i=i+1)
            if(i < win_size) temp_max = comp_max(temp_max, buffer[i]);
        max_val <= temp_max;
    end
endmodule