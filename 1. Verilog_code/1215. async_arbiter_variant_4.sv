//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
// Module: async_arbiter_top
// Description: Top-level asynchronous arbiter with modular architecture
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////////////////////////
module async_arbiter_top #(
    parameter WIDTH = 4
) (
    input  [WIDTH-1:0] req_i,
    output [WIDTH-1:0] grant_o
);
    // Internal signals
    wire [WIDTH-1:0] priority_mask;
    
    // Priority encoder module to generate mask
    priority_encoder #(
        .WIDTH(WIDTH)
    ) priority_enc_inst (
        .request(req_i),
        .mask(priority_mask)
    );
    
    // Grant generation module
    grant_generator #(
        .WIDTH(WIDTH)
    ) grant_gen_inst (
        .request(req_i),
        .mask(priority_mask),
        .grant(grant_o)
    );
    
endmodule

///////////////////////////////////////////////////////////////////////////////
// Module: priority_encoder
// Description: Generates priority mask for the highest priority request
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////////////////////////
module priority_encoder #(
    parameter WIDTH = 4
) (
    input  [WIDTH-1:0] request,
    output [WIDTH-1:0] mask
);
    // Isolate the least significant '1' in the request vector
    // This implements (~req_i + 1) & req_i efficiently
    assign mask = request & (~request + 1);
    
endmodule

///////////////////////////////////////////////////////////////////////////////
// Module: grant_generator
// Description: Applies priority mask to generate grant signals
// Standard: IEEE 1364-2005
///////////////////////////////////////////////////////////////////////////////
module grant_generator #(
    parameter WIDTH = 4
) (
    input  [WIDTH-1:0] request,
    input  [WIDTH-1:0] mask,
    output [WIDTH-1:0] grant
);
    // Apply mask to generate grant output
    // The mask already contains only the highest priority bit
    assign grant = mask & request;
    
endmodule