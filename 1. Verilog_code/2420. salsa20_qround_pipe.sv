module salsa20_qround_pipe (
    input clk, en,
    input [31:0] a, b, c, d,
    output reg [31:0] a_out, d_out
);
    reg [31:0] stage1, stage2;
    
    always @(posedge clk) begin
        if (en) begin
            // Stage 1: Addition and rotation
            stage1 <= b + ((a + d) <<< 7);
            
            // Stage 2: XOR and rotation
            stage2 <= c ^ ((stage1 + a) <<< 9);
            
            // Final outputs
            a_out <= a ^ stage2;
            d_out <= d + stage2;
        end
    end
endmodule
