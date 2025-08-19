module log_pipeline(
    input clk, 
    input en, 
    input [15:0] in, 
    output [15:0] out
);
    // 修改为标准的数组声明方式
    reg [15:0] pipe [0:3];
    
    // 函数计算log2值，替换$clog2(in)
    function integer log2;
        input [15:0] value;
        integer i;
        begin
            log2 = 0;
            for (i = 15; i >= 0; i = i - 1)
                if (value[i]) log2 = i;
        end
    endfunction
    
    always @(posedge clk)
        if(en) begin
            pipe[3] <= pipe[2];
            pipe[2] <= pipe[1];
            pipe[1] <= pipe[0];
            pipe[0] <= in + log2(in);
        end
    
    assign out = pipe[3];
endmodule