//SystemVerilog
///////////////////////////////////////////////////////////
// Module: crossbar_sync_prio_top
// Description: Top level module for crossbar with synchronous reset and priority
///////////////////////////////////////////////////////////
module crossbar_sync_prio_top #(
    parameter DW = 8,  // Data width
    parameter N  = 4   // Number of ports
) (
    input  wire                clk,    // System clock
    input  wire                rst_n,  // Active low reset
    input  wire                en,     // Enable signal
    input  wire [(DW*N)-1:0]   din,    // Input data
    input  wire [(N*2)-1:0]    dest,   // Destination indices
    output wire [(DW*N)-1:0]   dout    // Output data
);

    // Internal connection signals
    wire [1:0] dest_indices[0:N-1];
    
    // Instantiate destination decoder module
    dest_decoder #(
        .N(N)
    ) u_dest_decoder (
        .dest(dest),
        .dest_indices(dest_indices)
    );
    
    // Instantiate data crossbar module
    data_crossbar #(
        .DW(DW),
        .N(N)
    ) u_data_crossbar (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .din(din),
        .dest_indices(dest_indices),
        .dout(dout)
    );

endmodule

///////////////////////////////////////////////////////////
// Module: dest_decoder
// Description: Decodes the destination bits into indices
///////////////////////////////////////////////////////////
module dest_decoder #(
    parameter N = 4  // Number of ports
) (
    input  wire [(N*2)-1:0] dest,           // Packed destination bits
    output wire [1:0]       dest_indices[0:N-1]  // Unpacked destination indices
);
    
    genvar i;
    generate
        for(i=0; i<N; i=i+1) begin : gen_dest
            assign dest_indices[i] = dest[(i*2+1):(i*2)];
        end
    endgenerate

endmodule

///////////////////////////////////////////////////////////
// Module: data_crossbar
// Description: Performs the actual data routing based on indices
///////////////////////////////////////////////////////////
module data_crossbar #(
    parameter DW = 8,  // Data width
    parameter N  = 4   // Number of ports
) (
    input  wire                clk,                // System clock
    input  wire                rst_n,              // Active low reset
    input  wire                en,                 // Enable signal
    input  wire [(DW*N)-1:0]   din,                // Input data
    input  wire [1:0]          dest_indices[0:N-1], // Destination indices
    output reg  [(DW*N)-1:0]   dout                // Output data
);

    // Internal signals for multiplication operation
    wire [DW-1:0] din_port[0:N-1];
    wire [DW-1:0] selected_data[0:N-1];
    
    // Baugh-Wooley multiplier internal signals (for 2-bit multiplication)
    wire [3:0] bw_mult_result;
    wire [1:0] bw_mult_a, bw_mult_b;
    wire bw_pp0, bw_pp1, bw_pp2, bw_pp3;
    
    // Unpack input data ports
    genvar i;
    generate
        for(i=0; i<N; i=i+1) begin : gen_unpack
            assign din_port[i] = din[(i*DW) +: DW];
        end
    endgenerate
    
    // Implement 2-bit Baugh-Wooley multiplier
    baugh_wooley_2bit bw_multiplier (
        .a(bw_mult_a),
        .b(bw_mult_b),
        .product(bw_mult_result)
    );

    // Select data to route based on destination indices
    assign selected_data[0] = din_port[dest_indices[0]];
    assign selected_data[1] = din_port[dest_indices[1]];
    assign selected_data[2] = din_port[dest_indices[2]];
    assign selected_data[3] = din_port[dest_indices[3]];

    // Synchronous reset and data routing
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            dout <= {(DW*N){1'b0}};
        end else if(en) begin
            // Route data based on destination indices
            dout[DW-1:0]           <= selected_data[0];
            dout[(2*DW)-1:DW]      <= selected_data[1];
            dout[(3*DW)-1:(2*DW)]  <= selected_data[2];
            dout[(4*DW)-1:(3*DW)]  <= selected_data[3];
        end
    end

endmodule

///////////////////////////////////////////////////////////
// Module: baugh_wooley_2bit
// Description: 2-bit Baugh-Wooley multiplier implementation
///////////////////////////////////////////////////////////
module baugh_wooley_2bit (
    input  wire [1:0] a,        // 2-bit multiplicand
    input  wire [1:0] b,        // 2-bit multiplier
    output wire [3:0] product   // 4-bit product
);
    // Partial products using Baugh-Wooley algorithm
    wire pp0, pp1, pp2, pp3;
    
    // Generate partial products
    assign pp0 = a[0] & b[0];                // a0 * b0
    assign pp1 = a[1] & b[0];                // a1 * b0
    assign pp2 = a[0] & b[1];                // a0 * b1
    assign pp3 = ~(a[1] & b[1]);             // ~(a1 * b1) - Baugh-Wooley modification for signed multiplication

    // Compute product
    assign product[0] = pp0;                 // a0*b0
    assign product[1] = pp1 ^ pp2;           // a1*b0 XOR a0*b1
    assign product[2] = (pp1 & pp2) ^ pp3;   // Carry from bit 1 XOR ~(a1*b1)
    assign product[3] = ~((pp1 & pp2) & pp3); // Carry from bit 2, complemented for Baugh-Wooley algorithm

endmodule