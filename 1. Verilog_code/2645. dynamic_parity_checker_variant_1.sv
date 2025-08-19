//SystemVerilog
module dynamic_parity_checker #(
    parameter MAX_WIDTH = 64
)(
    input [$clog2(MAX_WIDTH)-1:0] width,
    input [MAX_WIDTH-1:0] data,
    output reg parity
);

    // 使用always块替代连续赋值和generate块，提高可读性
    integer j;
    
    always @(*) begin
        reg [MAX_WIDTH:0] temp_chain;
        temp_chain[0] = 1'b0;
        
        for (j = 0; j < MAX_WIDTH; j = j + 1) begin
            temp_chain[j+1] = (j < width) ? temp_chain[j] ^ data[j] : temp_chain[j];
        end
        
        parity = temp_chain[MAX_WIDTH];
    end

endmodule