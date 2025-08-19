module seq_detector_0110(
    input wire clk, rst_n, x,
    output reg z
);
    parameter S0=2'b00, S1=2'b01, S2=2'b10, S3=2'b11;
    reg [1:0] state, next_state;
    
    always @(posedge clk or negedge rst_n)
        if (!rst_n) state <= S0;
        else state <= next_state;
    
    always @(*) begin
        case (state)
            S0: next_state = x ? S1 : S0;
            S1: next_state = x ? S1 : S2;
            S2: next_state = x ? S3 : S0;
            S3: next_state = x ? S1 : S2;
            default: next_state = S0;
        endcase
        z = (state == S3) && (x == 0);
    end
endmodule