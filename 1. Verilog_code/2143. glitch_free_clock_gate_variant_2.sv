//SystemVerilog
module glitch_free_clock_gate (
    input  wire clk_in,
    input  wire enable,
    input  wire rst_n,
    output wire clk_out
);
    // Register for enable signal with pipelined architecture
    reg enable_ff1;
    reg enable_ff2;
    
    // Combinational logic for clock gating
    wire gated_clk_comb;
    
    // Output register after retiming
    reg clk_out_reg;
    
    // First stage register - remains at input
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            enable_ff1 <= 1'b0;
        end else begin
            enable_ff1 <= enable;
        end
    end
    
    // Second stage register - creating delay element for glitch-free operation
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            enable_ff2 <= 1'b0;
        end else begin
            enable_ff2 <= enable_ff1;
        end
    end
    
    // Combinational logic for clock gating
    assign gated_clk_comb = clk_in & enable_ff2;
    
    // Output register - moved after combinational logic
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            clk_out_reg <= 1'b0;
        end else begin
            clk_out_reg <= gated_clk_comb;
        end
    end
    
    // Final output assignment
    assign clk_out = clk_out_reg;
endmodule