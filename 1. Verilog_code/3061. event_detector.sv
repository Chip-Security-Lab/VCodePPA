module event_detector(
    input wire clk, rst_n,
    input wire [1:0] event_in,
    output reg detected
);
    localparam [3:0] S0 = 4'b0001, S1 = 4'b0010, 
                    S2 = 4'b0100, S3 = 4'b1000;
    reg [3:0] state, next;
    
    always @(negedge clk or negedge rst_n)
        if (!rst_n) state <= S0;
        else state <= next;
    
    always @(*) begin
        detected = 1'b0;
        case (state)
            S0: case (event_in)
                2'b00: next = S0;
                2'b01: next = S1;
                2'b10: next = S0;
                2'b11: next = S2;
            endcase
            S1: case (event_in)
                2'b00: next = S0;
                2'b01: next = S1;
                2'b10: next = S3;
                2'b11: next = S2;
            endcase
            S2: case (event_in)
                2'b00: next = S0;
                2'b01: next = S1;
                2'b10: next = S3;
                2'b11: next = S2;
            endcase
            S3: begin
                detected = 1'b1;
                next = S0;
            end
            default: next = S0;
        endcase
    end
endmodule