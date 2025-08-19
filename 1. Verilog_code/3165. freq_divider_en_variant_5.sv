//SystemVerilog
module freq_divider_en(
    input i_Clock,
    input i_Enable,
    input i_Reset,
    output reg o_Clock
);
    reg [3:0] r_Count;
    wire [3:0] w_Next_Count;
    wire w_Carry;
    
    // Carry Lookahead Adder Implementation
    wire [3:0] w_P, w_G;
    wire [3:0] w_C;
    
    // Generate and Propagate signals
    assign w_P = r_Count ^ 4'b0001;
    assign w_G = r_Count & 4'b0001;
    
    // Carry Lookahead logic
    assign w_C[0] = 1'b0;
    assign w_C[1] = w_G[0] | (w_P[0] & w_C[0]);
    assign w_C[2] = w_G[1] | (w_P[1] & w_G[0]) | (w_P[1] & w_P[0] & w_C[0]);
    assign w_C[3] = w_G[2] | (w_P[2] & w_G[1]) | (w_P[2] & w_P[1] & w_G[0]) | (w_P[2] & w_P[1] & w_P[0] & w_C[0]);
    
    // Sum calculation
    assign w_Next_Count = w_P ^ w_C;
    
    always @(posedge i_Clock or posedge i_Reset) begin
        if (i_Reset) begin
            r_Count <= 4'd0;
            o_Clock <= 1'b0;
        end else if (i_Enable) begin
            if (r_Count == 4'd7) begin
                r_Count <= 4'd0;
                o_Clock <= ~o_Clock;
            end else
                r_Count <= w_Next_Count;
        end
    end
endmodule