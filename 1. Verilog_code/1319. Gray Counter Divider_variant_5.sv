//SystemVerilog
module gray_counter_div (
    input wire clk, rst,
    output wire divided_clk
);
    reg [3:0] gray_count;
    reg divided_clk_reg;
    
    wire gray_count0_next;
    wire and_result;
    
    // Complemented input moved before the register
    assign gray_count0_next = ~gray_count[0];
    
    // Pre-compute the AND term used in multiple expressions
    assign and_result = gray_count[1] & gray_count[0];
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            gray_count <= 4'b0000;
            divided_clk_reg <= 1'b0;
        end else begin
            // Update gray counter with forward retiming
            gray_count[0] <= gray_count0_next;
            gray_count[1] <= gray_count[1] ^ gray_count[0];
            gray_count[2] <= gray_count[2] ^ and_result;
            gray_count[3] <= gray_count[3] ^ (and_result & gray_count[2]);
            
            // Register the output to improve timing
            divided_clk_reg <= gray_count[3];
        end
    end
    
    // Output assignment
    assign divided_clk = divided_clk_reg;
endmodule