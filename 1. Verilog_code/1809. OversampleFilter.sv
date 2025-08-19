module OversampleFilter #(parameter OVERSAMPLE=3) (
    input clk, 
    input din,
    output reg dout
);
    reg [OVERSAMPLE-1:0] sample_buf;
    reg [3:0] count; // 计数1的数量
    integer i;
    
    always @(posedge clk) begin
        // 移位寄存器
        sample_buf <= {sample_buf[OVERSAMPLE-2:0], din};
        
        // 计数1的数量
        count = 0;
        for(i=0; i<OVERSAMPLE; i=i+1)
            if(sample_buf[i]) count = count + 1;
        
        // 多数表决
        dout <= (count > (OVERSAMPLE/2));
    end
endmodule