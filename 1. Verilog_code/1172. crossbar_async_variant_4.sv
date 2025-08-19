//SystemVerilog
//===================================================================
// Hierarchical Asynchronous Crossbar Implementation
//===================================================================

module crossbar_async #(
    parameter WIDTH  = 16,
    parameter INPUTS = 3,
    parameter OUTPUTS = 3
)(
    input  [(WIDTH*INPUTS)-1:0] in_data,
    input  [(OUTPUTS*INPUTS)-1:0] req,
    output [(WIDTH*OUTPUTS)-1:0] out_data
);

    genvar o;
    generate 
        for(o=0; o<OUTPUTS; o=o+1) begin : gen_out
            wire [INPUTS-1:0] req_vec;
            wire [WIDTH-1:0] selected_data;
            wire valid_request;
            
            // Request extractor submodule
            request_extractor #(
                .INPUTS(INPUTS),
                .OUTPUTS(OUTPUTS)
            ) req_extract (
                .req(req),
                .output_index(o),
                .req_vec(req_vec),
                .valid_request(valid_request)
            );
            
            // Priority encoder submodule
            priority_encoder #(
                .WIDTH(WIDTH),
                .INPUTS(INPUTS)
            ) pri_enc (
                .in_data(in_data),
                .req_vec(req_vec),
                .selected_data(selected_data)
            );
            
            // Output data selector
            output_selector #(
                .WIDTH(WIDTH)
            ) out_sel (
                .selected_data(selected_data),
                .valid_request(valid_request),
                .out_data(out_data[(o+1)*WIDTH-1:o*WIDTH])
            );
        end
    endgenerate
endmodule

//===================================================================
// Request Extractor Module
//===================================================================
module request_extractor #(
    parameter INPUTS = 3,
    parameter OUTPUTS = 3
)(
    input  [(OUTPUTS*INPUTS)-1:0] req,
    input  [$clog2(OUTPUTS)-1:0] output_index,
    output [INPUTS-1:0] req_vec,
    output valid_request
);
    
    genvar i;
    generate
        for(i=0; i<INPUTS; i=i+1) begin : gen_req
            assign req_vec[i] = req[i*OUTPUTS + output_index];
        end
    endgenerate
    
    // Determine if there's any valid request
    assign valid_request = |req_vec;
    
endmodule

//===================================================================
// Priority Encoder Module
//===================================================================
module priority_encoder #(
    parameter WIDTH = 16,
    parameter INPUTS = 3
)(
    input  [(WIDTH*INPUTS)-1:0] in_data,
    input  [INPUTS-1:0] req_vec,
    output reg [WIDTH-1:0] selected_data
);
    // Internal signals for priority detection
    reg [INPUTS-1:0] priority_mask;
    wire [WIDTH-1:0] data_sources [0:INPUTS-1];
    
    // Extract individual data sources for better readability
    genvar i;
    generate
        for (i = 0; i < INPUTS; i = i + 1) begin : data_source_extraction
            assign data_sources[i] = in_data[(i+1)*WIDTH-1:i*WIDTH];
        end
    endgenerate
    
    // Priority detection logic
    // Determines which input has highest priority (lower index has higher priority)
    always @(*) begin : priority_detection
        integer j;
        priority_mask = {INPUTS{1'b0}};
        
        for (j = 0; j < INPUTS; j = j + 1) begin
            if (req_vec[j] && priority_mask == {INPUTS{1'b0}}) begin
                priority_mask[j] = 1'b1;
            end
        end
    end
    
    // Data selection logic
    // Selects data from the highest priority input that has an active request
    always @(*) begin : data_selection
        integer k;
        selected_data = {WIDTH{1'b0}};
        
        for (k = 0; k < INPUTS; k = k + 1) begin
            if (priority_mask[k]) begin
                selected_data = data_sources[k];
            end
        end
    end
    
endmodule

//===================================================================
// Output Selector Module with Han-Carlson Adder
//===================================================================
module output_selector #(
    parameter WIDTH = 16
)(
    input  [WIDTH-1:0] selected_data,
    input  valid_request,
    output [WIDTH-1:0] out_data
);
    wire [WIDTH-1:0] zero_data;
    assign zero_data = {WIDTH{1'b0}};
    
    // 8-bit Han-Carlson adder to process valid_request ? selected_data : 0
    han_carlson_adder #(
        .WIDTH(8)
    ) adder_inst (
        .a(valid_request ? selected_data[7:0] : 8'h00),
        .b(valid_request ? 8'h00 : 8'h00),
        .sum(out_data[7:0])
    );
    
    // For remaining bits if WIDTH > 8, pass through directly
    generate
        if (WIDTH > 8) begin : pass_remaining_bits
            assign out_data[WIDTH-1:8] = valid_request ? selected_data[WIDTH-1:8] : {(WIDTH-8){1'b0}};
        end
    endgenerate
    
endmodule

//===================================================================
// Han-Carlson Adder Module (8-bit)
//===================================================================
module han_carlson_adder #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    output [WIDTH-1:0] sum
);
    // Generate and Propagate signals
    wire [WIDTH-1:0] g, p;
    
    // Generate (g) and Propagate (p) for each bit position
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_gp
            assign g[i] = a[i] & b[i];
            assign p[i] = a[i] ^ b[i];
        end
    endgenerate
    
    // Group generate and propagate signals
    wire [WIDTH-1:0] g_even, p_even;
    wire [WIDTH-1:0] g_odd, p_odd;
    
    // Separate even and odd bit positions
    generate
        for (i = 0; i < WIDTH; i = i + 2) begin : even_bits
            assign g_even[i/2] = g[i];
            assign p_even[i/2] = p[i];
        end
        
        for (i = 1; i < WIDTH; i = i + 2) begin : odd_bits
            assign g_odd[i/2] = g[i];
            assign p_odd[i/2] = p[i];
        end
    endgenerate
    
    // Carry generation network - Han-Carlson style
    // Level 1: Prefix computation for even-indexed bits
    wire [WIDTH/2-1:0] gc1, pc1;
    
    generate
        for (i = 0; i < WIDTH/2; i = i + 1) begin : prefix_level1
            if (i == 0) begin
                assign gc1[i] = g_even[i];
                assign pc1[i] = p_even[i];
            end else begin
                assign gc1[i] = g_even[i] | (p_even[i] & g_even[i-1]);
                assign pc1[i] = p_even[i] & p_even[i-1];
            end
        end
    endgenerate
    
    // Level 2: Tree reduction
    wire [WIDTH/2-1:0] gc2, pc2;
    
    generate
        for (i = 0; i < WIDTH/2; i = i + 1) begin : prefix_level2
            if (i < 2) begin
                assign gc2[i] = gc1[i];
                assign pc2[i] = pc1[i];
            end else begin
                assign gc2[i] = gc1[i] | (pc1[i] & gc1[i-2]);
                assign pc2[i] = pc1[i] & pc1[i-2];
            end
        end
    endgenerate
    
    // Level 3: Final prefix computation for even-indexed bits
    wire [WIDTH/2-1:0] gc_final;
    
    generate
        for (i = 0; i < WIDTH/2; i = i + 1) begin : prefix_final
            assign gc_final[i] = gc2[i];
        end
    endgenerate
    
    // Compute carries for odd-indexed bits
    wire [WIDTH/2-1:0] carry_odd;
    
    generate
        for (i = 0; i < WIDTH/2; i = i + 1) begin : compute_odd_carries
            assign carry_odd[i] = g_odd[i] | (p_odd[i] & gc_final[i]);
        end
    endgenerate
    
    // Compute all carries
    wire [WIDTH-1:0] carry;
    assign carry[0] = 1'b0; // No carry-in for bit 0
    
    generate
        for (i = 1; i < WIDTH; i = i + 1) begin : assemble_carries
            if (i % 2 == 0) begin
                assign carry[i] = gc_final[i/2-1];
            end else begin
                assign carry[i] = carry_odd[i/2];
            end
        end
    endgenerate
    
    // Final sum computation
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : compute_sum
            assign sum[i] = p[i] ^ carry[i];
        end
    endgenerate
    
endmodule