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
    
    // 借位减法器信号
    wire [3:0] a, b;
    wire [3:0] diff;
    wire [4:0] borrow;
    
    // 借位减法器实现
    assign borrow[0] = 1'b0;
    
    genvar j;
    generate
        for(j=0; j<4; j=j+1) begin: borrow_subtractor
            assign diff[j] = a[j] ^ b[j] ^ borrow[j];
            assign borrow[j+1] = (~a[j] & b[j]) | (borrow[j] & ~(a[j] ^ b[j]));
        end
    endgenerate
    
    // 为比较操作分配信号
    assign a = i < MAX_WIN ? i : 4'b0;
    assign b = win_size;
    
    always @(posedge clk) begin
        // 手动移位缓冲区
        for(i=MAX_WIN-1; i>0; i=i-1)
            buffer[i] <= buffer[i-1];
        buffer[0] <= din;
        
        // 查找最大值 - 使用借位减法器进行比较
        temp_max = buffer[0];
        for(i=1; i<MAX_WIN; i=i+1) begin
            // 如果 i < win_size (使用借位减法器) 且 buffer[i] > temp_max
            if(!borrow[4] && buffer[i] > temp_max) 
                temp_max = buffer[i];
        end
        max_val <= temp_max;
    end
endmodule