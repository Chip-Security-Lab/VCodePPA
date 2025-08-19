//SystemVerilog
module jk_ff_async_reset (
    input wire clk,
    input wire rst_n,
    input wire j,
    input wire k,
    output reg q
);
    reg j_reg, k_reg;
    reg q_next, q_internal;
    
    // Register inputs to reduce input path delay
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            j_reg <= 1'b0;
            k_reg <= 1'b0;
        end else begin
            j_reg <= j;
            k_reg <= k;
        end
    end
    
    // Pre-compute next state with registered output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q_internal <= 1'b0;
        end else begin
            case ({j_reg, k_reg})
                2'b00: q_internal <= q;
                2'b01: q_internal <= 1'b0;
                2'b10: q_internal <= 1'b1;
                2'b11: q_internal <= ~q;
            endcase
        end
    end
    
    // Final output register stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            q <= 1'b0;
        else
            q <= q_internal;
    end
endmodule