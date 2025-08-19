//SystemVerilog
module SeqDetector #(parameter PATTERN=4'b1101) (
    input clk, rst_n,
    input data_in,
    output reg detected
);
    reg [2:0] state;
    wire [3:0] next_state;
    
    assign next_state = {state, data_in};
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= 3'b0;
            detected <= 1'b0;
        end
        else begin
            state <= next_state[2:0];
            detected <= (next_state == PATTERN);
        end
    end
endmodule