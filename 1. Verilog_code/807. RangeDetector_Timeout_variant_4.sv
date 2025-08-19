//SystemVerilog
module RangeDetector_Timeout #(
    parameter WIDTH = 8,
    parameter TIMEOUT = 10
)(
    input clk, rst_n,
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] threshold,
    output reg timeout
);
    reg [$clog2(TIMEOUT):0] counter;
    wire is_greater;
    wire [WIDTH-1:0] diff;
    wire [WIDTH:0] borrow;

    // 先行借位减法器实现比较运算
    // 通过减法结果来判断data_in是否大于threshold
    assign borrow[0] = 0;
    
    genvar i;
    generate
        for(i = 0; i < WIDTH; i = i + 1) begin: borrow_gen
            assign diff[i] = data_in[i] ^ threshold[i] ^ borrow[i];
            assign borrow[i+1] = (~data_in[i] & threshold[i]) | 
                                 (~data_in[i] & borrow[i]) | 
                                 (threshold[i] & borrow[i]);
        end
    endgenerate
    
    // 当最高位借位为0时，表示data_in > threshold
    assign is_greater = ~borrow[WIDTH];

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            counter <= 0;
            timeout <= 0;
        end
        else begin
            if(is_greater) begin
                counter <= (counter < TIMEOUT) ? counter + 1 : TIMEOUT;
            end
            else begin
                counter <= 0;
            end
            timeout <= (counter == TIMEOUT);
        end
    end
endmodule