//SystemVerilog
module Div2 #(parameter W=4)(
    input [W-1:0] a, b,
    output reg [W-1:0] q,
    output reg [W:0] r
);

    reg [1:0] state;
    reg [W-1:0] i;
    reg [W:0] r_temp;
    
    localparam IDLE = 2'b00;
    localparam SHIFT = 2'b01;
    localparam COMPARE = 2'b10;
    localparam UPDATE = 2'b11;

    always @(*) begin
        case(state)
            IDLE: begin
                r_temp = a;
                q = 0;
                i = W-1;
                state = SHIFT;
            end
            
            SHIFT: begin
                r_temp = r_temp << 1;
                state = COMPARE;
            end
            
            COMPARE: begin
                q[i] = (r_temp >= b);
                state = UPDATE;
            end
            
            UPDATE: begin
                if(q[i]) r_temp = r_temp - b;
                if(i > 0) begin
                    i = i - 1;
                    state = SHIFT;
                end else begin
                    r = r_temp;
                    state = IDLE;
                end
            end
            
            default: state = IDLE;
        endcase
    end
endmodule