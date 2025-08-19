module fsm_converter #(parameter S_WIDTH=4) (
    input [S_WIDTH-1:0] state_in,
    output reg [2**S_WIDTH-1:0] state_out
);
    integer i;
    
    // 修复默认值赋值
    always @(*) begin
        for(i=0; i<2**S_WIDTH; i=i+1) begin
            state_out[i] = (i == state_in) ? 1'b1 : 1'b0;
        end
    end
endmodule