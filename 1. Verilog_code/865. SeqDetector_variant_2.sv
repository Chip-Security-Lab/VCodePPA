//SystemVerilog
module SeqDetector #(parameter PATTERN=4'b1101) (
    input clk, rst_n,
    input data_in,
    output reg detected
);
    reg [3:0] state;
    wire pattern_match;
    
    // 使用组合逻辑进行模式匹配
    assign pattern_match = (state[3:0] == PATTERN);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= 4'b0000;
            detected <= 1'b0;
        end
        else begin
            state <= {state[2:0], data_in};
            detected <= pattern_match;
        end
    end
endmodule