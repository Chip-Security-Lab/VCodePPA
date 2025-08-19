//SystemVerilog
module signed_mult (
    input clk,
    input rst_n,
    input signed [7:0] a,
    input signed [7:0] b,
    input valid,
    output reg ready,
    output reg signed [15:0] p
);

    reg signed [15:0] p_reg;
    reg busy;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            p_reg <= 16'd0;
            p <= 16'd0;
            ready <= 1'b1;
            busy <= 1'b0;
        end
        else begin
            if (valid && ready) begin
                p_reg <= a * b;
                busy <= 1'b1;
                ready <= 1'b0;
            end
            else if (busy) begin
                p <= p_reg;
                busy <= 1'b0;
                ready <= 1'b1;
            end
        end
    end

endmodule