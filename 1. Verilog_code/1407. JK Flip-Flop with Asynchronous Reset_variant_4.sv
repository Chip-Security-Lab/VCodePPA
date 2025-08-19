//SystemVerilog
module jk_ff_async_reset (
    input wire clk,
    input wire rst_n,
    input wire j,
    input wire k,
    output reg q
);
    // Register j and k inputs to reduce input-to-register delay
    reg j_reg, k_reg;
    
    // Capture input signals
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            j_reg <= 1'b0;
            k_reg <= 1'b0;
        end
        else begin
            j_reg <= j;
            k_reg <= k;
        end
    end
    
    // Main flip-flop logic using registered inputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            q <= 1'b0;
        else begin
            case ({j_reg, k_reg})
                2'b00: q <= q;     // 保持
                2'b01: q <= 1'b0;  // 置0
                2'b10: q <= 1'b1;  // 置1
                2'b11: q <= ~q;    // 翻转
            endcase
        end
    end
endmodule