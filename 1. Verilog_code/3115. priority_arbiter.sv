module priority_arbiter(
    input wire clk,
    input wire reset,
    input wire [3:0] requests,
    output reg [3:0] grant,
    output reg busy
);
    parameter [1:0] IDLE = 2'b00, GRANT0 = 2'b01, GRANT1 = 2'b10, GRANT2 = 2'b11;
    reg [1:0] state, next_state;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            grant <= 4'b0000;
            busy <= 1'b0;
        end else begin
            state <= next_state;
            
            case (state)
                IDLE: begin
                    grant <= 4'b0000;
                    busy <= 1'b0;
                end
                GRANT0: begin
                    grant <= 4'b0001;
                    busy <= 1'b1;
                end
                GRANT1: begin
                    grant <= 4'b0010;
                    busy <= 1'b1;
                end
                GRANT2: begin
                    grant <= 4'b0100;
                    busy <= 1'b1;
                end
                default: begin
                    grant <= 4'b1000;
                    busy <= 1'b1;
                end
            endcase
        end
    end
    
    always @(*) begin
        if (requests == 4'b0000)
            next_state = IDLE;
        else if (requests[0])
            next_state = GRANT0;
        else if (requests[1])
            next_state = GRANT1;
        else if (requests[2])
            next_state = GRANT2;
        else
            next_state = 2'b11; // GRANT3
    end
endmodule
