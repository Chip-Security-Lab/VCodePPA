//SystemVerilog
// SystemVerilog
module crossbar_async #(
    parameter WIDTH=16,
    parameter INPUTS=3,
    parameter OUTPUTS=3
) (
    input  [(WIDTH*INPUTS)-1:0]    in_data,
    input  [(OUTPUTS*INPUTS)-1:0]  req,
    output [(WIDTH*OUTPUTS)-1:0]   out_data
);

    // Stage 1: Request processing pipeline
    wire [INPUTS-1:0] req_vec [OUTPUTS-1:0];
    reg  [INPUTS-1:0] req_vec_reg [OUTPUTS-1:0];
    reg  [OUTPUTS-1:0] any_req_reg;
    
    // Stage 2: Arbiter pipeline
    reg  [1:0] selected_index_reg [OUTPUTS-1:0];
    reg  [OUTPUTS-1:0] input_selected_reg;
    
    // Stage 3: Data selection pipeline
    reg  [(WIDTH*OUTPUTS)-1:0] out_data_reg;
    
    // Data path extraction for better organization
    wire [WIDTH-1:0] data_slices [INPUTS-1:0];
    
    genvar i, o;
    generate
        // Extract data slices for better readability
        for (i = 0; i < INPUTS; i = i + 1) begin : gen_data_slices
            assign data_slices[i] = in_data[(i+1)*WIDTH-1:i*WIDTH];
        end
        
        // First stage - Extract and register request vectors
        for (o = 0; o < OUTPUTS; o = o + 1) begin : gen_req_vec
            for (i = 0; i < INPUTS; i = i + 1) begin : gen_req
                assign req_vec[o][i] = req[i*OUTPUTS + o];
            end
            
            // Pipeline register for request vectors
            always @(*) begin
                req_vec_reg[o] = req_vec[o];
                any_req_reg[o] = |req_vec[o];
            end
        end
        
        // Second stage - Priority encoding and selection
        for (o = 0; o < OUTPUTS; o = o + 1) begin : gen_priority
            wire input_selected;
            wire [1:0] selected_index;
            
            // Improved priority encoder with reduced logic depth
            optimized_priority_encoder prioritizer (
                .req_vec(req_vec_reg[o]),
                .input_selected(input_selected),
                .selected_index(selected_index)
            );
            
            // Pipeline register for selection results
            always @(*) begin
                selected_index_reg[o] = selected_index;
                input_selected_reg[o] = input_selected;
            end
        end
        
        // Third stage - Data selection and output generation
        for (o = 0; o < OUTPUTS; o = o + 1) begin : gen_output
            wire [WIDTH-1:0] out_temp;
            
            // Optimized data selector with balanced tree structure
            optimized_data_selector #(.WIDTH(WIDTH)) selector (
                .data_slices(data_slices),
                .selected_index(selected_index_reg[o]),
                .out_data(out_temp)
            );
            
            // Output assignment with validation
            always @(*) begin
                out_data_reg[(o+1)*WIDTH-1:o*WIDTH] = any_req_reg[o] ? out_temp : {WIDTH{1'b0}};
            end
        end
    endgenerate
    
    // Final output assignment
    assign out_data = out_data_reg;
    
endmodule

// Optimized priority encoder with reduced logic depth
module optimized_priority_encoder (
    input [2:0] req_vec,
    output reg input_selected,
    output reg [1:0] selected_index
);
    // Pre-compute common terms
    wire req0 = req_vec[0];
    wire req1 = req_vec[1];
    wire req2 = req_vec[2];
    
    // Simplified priority logic with balanced critical path
    always @(*) begin
        input_selected = req0 | req1 | req2;
        
        casez (req_vec)
            3'b??1: selected_index = 2'b00; // Highest priority (index 0)
            3'b?10: selected_index = 2'b01; // Medium priority (index 1)
            3'b100: selected_index = 2'b10; // Lowest priority (index 2)
            default: selected_index = 2'b00; // Default case
        endcase
    end
endmodule

// Optimized data selector with balanced tree structure
module optimized_data_selector #(
    parameter WIDTH=16
) (
    input [WIDTH-1:0] data_slices [2:0],
    input [1:0] selected_index,
    output [WIDTH-1:0] out_data
);
    // Select from data slices using simplified mux tree
    reg [WIDTH-1:0] result;
    
    always @(*) begin
        case (selected_index)
            2'b00: result = data_slices[0];
            2'b01: result = data_slices[1];
            2'b10: result = data_slices[2];
            default: result = {WIDTH{1'b0}};
        endcase
    end
    
    assign out_data = result;
endmodule