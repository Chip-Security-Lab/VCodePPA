// 首先定义函数，然后再使用它
function integer log2;
    input integer v;
    begin
        log2=0;
        while(v>>1) begin
            log2=log2+1;
            v = v >> 1;
        end
    end
endfunction

module int_ctrl_sync_priority #(WIDTH=8) (
    input clk, rst_n,
    input [WIDTH-1:0] int_src,
    output reg [log2(WIDTH)-1:0] int_id
);

reg [log2(WIDTH)-1:0] priority_value;
integer i;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n) int_id <= 0;
    else int_id <= priority_value;
end

// 组合逻辑实现priority encoder
always @(*) begin
    priority_value = 0;
    for(i=0; i<WIDTH; i=i+1)
        if(int_src[i]) priority_value = i;
end

endmodule