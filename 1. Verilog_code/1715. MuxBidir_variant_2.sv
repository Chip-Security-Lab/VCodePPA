//SystemVerilog
module MuxBidir #(parameter W=8) (
    inout [W-1:0] bus_a,
    inout [W-1:0] bus_b,
    output [W-1:0] bus_out,
    input sel, oe
);

    // Internal signals
    wire [W-1:0] bus_a_in;
    wire [W-1:0] bus_b_in;
    wire [W-1:0] bus_a_out;
    wire [W-1:0] bus_b_out;
    
    // Input path with parallel prefix logic
    genvar i;
    generate
        for(i=0; i<W; i=i+1) begin : gen_input
            // Parallel prefix input stage
            wire sel_delayed;
            wire [1:0] sel_encoded;
            
            // Encode select signal
            assign sel_encoded = {sel, ~sel};
            
            // Input selection with parallel prefix
            assign bus_a_in[i] = bus_a[i] & sel_encoded[1];
            assign bus_b_in[i] = bus_b[i] & sel_encoded[0];
        end
    endgenerate
    
    // Output path with parallel prefix logic
    generate
        for(i=0; i<W; i=i+1) begin : gen_output
            // Parallel prefix output stage
            wire [1:0] oe_sel;
            wire [1:0] out_sel;
            
            // Encode output enable and select
            assign oe_sel = {oe & sel, oe & ~sel};
            
            // Output selection with parallel prefix
            assign bus_a[i] = (oe_sel[1]) ? bus_out[i] : 1'bz;
            assign bus_b[i] = (oe_sel[0]) ? bus_out[i] : 1'bz;
        end
    endgenerate
    
    // Mux logic with parallel prefix
    generate
        for(i=0; i<W; i=i+1) begin : gen_mux
            // Parallel prefix mux stage
            wire [1:0] mux_sel;
            
            // Encode mux select
            assign mux_sel = {sel, ~sel};
            
            // Mux selection with parallel prefix
            assign bus_out[i] = (bus_a_in[i] & mux_sel[1]) | (bus_b_in[i] & mux_sel[0]);
        end
    endgenerate

endmodule