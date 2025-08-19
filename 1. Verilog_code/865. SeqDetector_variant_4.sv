//SystemVerilog
module SeqDetector #(parameter PATTERN=4'b1101) (
    input clk, rst_n,
    input data_in,
    output reg detected
);
    reg [2:0] state;
    reg data_in_reg;
    wire pattern_detected;
    
    assign pattern_detected = (state == PATTERN[3:1]) && (data_in_reg == PATTERN[0]);
    
    always @(posedge clk or negedge rst_n) begin
        state <= !rst_n ? 3'b000 : {state[1:0], data_in};
        data_in_reg <= !rst_n ? 1'b0 : data_in;
        detected <= !rst_n ? 1'b0 : pattern_detected;
    end
endmodule