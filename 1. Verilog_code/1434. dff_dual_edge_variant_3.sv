//SystemVerilog
module dff_dual_edge (
    input clk, rstn,
    input d,
    output q
);
    reg q_pos, q_neg;
    wire q_mux;

    // Positive edge FF - moved after input logic
    always @(posedge clk or negedge rstn) begin
        if (!rstn) q_pos <= 1'b0;
        else       q_pos <= d;
    end

    // Negative edge FF - moved after input logic
    always @(negedge clk or negedge rstn) begin
        if (!rstn) q_neg <= 1'b0;
        else       q_neg <= d;
    end

    // Simplified multiplexer implementation using continuous assignment
    assign q_mux = clk ? q_pos : q_neg;
    
    // Output register to balance timing paths
    reg q_reg;
    always @(q_mux) begin
        q_reg = q_mux;
    end

    assign q = q_reg;
endmodule