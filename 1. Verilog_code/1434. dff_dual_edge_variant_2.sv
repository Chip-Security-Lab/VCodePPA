//SystemVerilog
//IEEE 1364-2005 Verilog
module dff_dual_edge (
    input wire clk, rstn,
    input wire d,
    output wire q
);
    reg q_pos, q_neg;
    wire mux_sel;
    wire mux_out;
    wire [1:0] mux_inputs;

    // Positive edge FF
    always @(posedge clk or negedge rstn) begin
        if (!rstn) 
            q_pos <= 1'b0;
        else       
            q_pos <= d;
    end

    // Negative edge FF
    always @(negedge clk or negedge rstn) begin
        if (!rstn) 
            q_neg <= 1'b0;
        else       
            q_neg <= d;
    end

    // Explicit multiplexer implementation
    assign mux_inputs = {q_pos, q_neg};  // [1]=q_pos, [0]=q_neg
    assign mux_sel = clk;
    assign mux_out = mux_inputs[mux_sel];
    assign q = mux_out;

endmodule