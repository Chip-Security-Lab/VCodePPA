//SystemVerilog
module neg_edge_siso #(parameter DEPTH = 4) (
    input wire clk_n, arst_n, sin,
    output wire sout
);
    // Forward retimed shift register implementation
    reg [DEPTH-2:0] sr_array;
    reg input_stage;
    
    // Input stage register moved forward through combinational logic
    always @(negedge clk_n or negedge arst_n) begin
        if (!arst_n)
            input_stage <= 1'b0;
        else
            input_stage <= sin;
    end
    
    // Main shift register with reduced depth
    always @(negedge clk_n or negedge arst_n) begin
        if (!arst_n)
            sr_array <= 0;
        else
            sr_array <= {sr_array[DEPTH-3:0], input_stage};
    end
    
    // Output is directly from the shift register
    assign sout = sr_array[DEPTH-2];
endmodule