//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
// File: crossbar_sync_prio_top.v
// Description: Crossbar switch with synchronous reset and priority routing
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////////////////////////

module crossbar_sync_prio_top #(
    parameter DW = 8,  // Data width
    parameter N = 4    // Number of ports
)(
    input wire clk,                // System clock
    input wire rst_n,              // Active low reset
    input wire en,                 // Enable signal
    input wire [(DW*N)-1:0] din,   // Input data bus
    input wire [(N*2)-1:0] dest,   // Destination indices
    output wire [(DW*N)-1:0] dout  // Output data bus
);

    // Pre-decode destination indices to reduce critical path
    wire [1:0] dest_indices[0:N-1];
    
    // Internal data path with pipelining opportunity
    wire [(DW*N)-1:0] mux_out;
    
    // Instantiate optimized destination decoder module
    dest_decoder_opt #(
        .N(N)
    ) u_dest_decoder (
        .dest(dest),
        .dest_indices(dest_indices)
    );
    
    // Instantiate optimized crosspoint multiplexer module
    crosspoint_mux_opt #(
        .DW(DW),
        .N(N)
    ) u_crosspoint_mux (
        .din(din),
        .dest_indices(dest_indices),
        .mux_out(mux_out)
    );
    
    // Instantiate optimized output register module
    output_register_opt #(
        .DW(DW),
        .N(N)
    ) u_output_register (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .data_in(mux_out),
        .data_out(dout)
    );

endmodule

///////////////////////////////////////////////////////////////////////////////
// Optimized destination decoder module
///////////////////////////////////////////////////////////////////////////////
module dest_decoder_opt #(
    parameter N = 4    // Number of ports
)(
    input wire [(N*2)-1:0] dest,             // Destination bus
    output wire [1:0] dest_indices[0:N-1]    // Decoded destination indices
);

    // Direct bit extraction for faster decoding
    genvar i;
    generate
        for(i=0; i<N; i=i+1) begin : gen_dest
            // Explicit bit selection to optimize synthesis
            assign dest_indices[i][0] = dest[i*2];
            assign dest_indices[i][1] = dest[i*2+1];
        end
    endgenerate

endmodule

///////////////////////////////////////////////////////////////////////////////
// Optimized crosspoint multiplexer module with balanced paths
// Using shift-and-add multiplication algorithm for 2-bit operations
///////////////////////////////////////////////////////////////////////////////
module crosspoint_mux_opt #(
    parameter DW = 8,  // Data width
    parameter N = 4    // Number of ports
)(
    input wire [(DW*N)-1:0] din,             // Input data
    input wire [1:0] dest_indices[0:N-1],    // Destination indices
    output wire [(DW*N)-1:0] mux_out         // Multiplexed output
);

    // Break down the large mux operations into smaller chunks for better timing
    wire [DW-1:0] din_chunks [0:N-1];
    wire [DW-1:0] mux_chunks [0:N-1];
    
    // Extract data chunks for easier indexing and better path balancing
    genvar i;
    generate
        for(i=0; i<N; i=i+1) begin : gen_chunks
            assign din_chunks[i] = din[(i+1)*DW-1:i*DW];
        end
    endgenerate

    // Implement multiplexer with balanced structure and shift-add multiplication
    genvar j;
    generate
        for(j=0; j<N; j=j+1) begin : gen_mux
            // Shift-and-add multiplication based selector implementation
            // This replaces the direct multiplexer with a more efficient structure
            wire [DW-1:0] partial_result_0, partial_result_1;
            wire [1:0] index = dest_indices[j];
            
            // First bit processing
            assign partial_result_0 = index[0] ? din_chunks[1] : din_chunks[0];
            
            // Second bit processing - shift and add approach
            assign partial_result_1 = index[1] ? 
                  (din_chunks[2] | (index[0] ? din_chunks[1] : {DW{1'b0}})) :
                  partial_result_0;
            
            // Connect output chunks
            assign mux_chunks[j] = partial_result_1;
            assign mux_out[(j+1)*DW-1:j*DW] = mux_chunks[j];
        end
    endgenerate

endmodule

///////////////////////////////////////////////////////////////////////////////
// Optimized output register module
///////////////////////////////////////////////////////////////////////////////
module output_register_opt #(
    parameter DW = 8,  // Data width
    parameter N = 4    // Number of ports
)(
    input wire clk,                      // System clock
    input wire rst_n,                    // Active low reset
    input wire en,                       // Enable signal
    input wire [(DW*N)-1:0] data_in,     // Input data
    output reg [(DW*N)-1:0] data_out     // Registered output data
);

    // Partition registers for better timing closure
    genvar k;
    generate
        for(k=0; k<N; k=k+1) begin : gen_reg
            // Register each output chunk separately for better timing
            always @(posedge clk or negedge rst_n) begin
                if(!rst_n) begin
                    data_out[(k+1)*DW-1:k*DW] <= {DW{1'b0}};
                end else if(en) begin
                    data_out[(k+1)*DW-1:k*DW] <= data_in[(k+1)*DW-1:k*DW];
                end
            end
        end
    endgenerate

endmodule