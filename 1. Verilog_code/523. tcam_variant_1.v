module tcam #(parameter WIDTH=32, DEPTH=64)(
    input clk,
    input rst_n,
    input write_en,
    input [$clog2(DEPTH)-1:0] write_addr,
    input [WIDTH-1:0] write_data,
    input [WIDTH-1:0] write_mask,
    input [WIDTH-1:0] data_in,
    input [WIDTH-1:0] mask_in,
    input valid_in,
    output reg valid_out,
    output reg [DEPTH-1:0] hit_lines
);

    // TCAM memory arrays
    reg [WIDTH-1:0] tcam_data [0:DEPTH-1];
    reg [WIDTH-1:0] tcam_mask [0:DEPTH-1];
    
    // Pipeline stage 1: Input registers
    reg [WIDTH-1:0] data_in_reg;
    reg [WIDTH-1:0] mask_in_reg;
    reg valid_stage1;
    
    // Pipeline stage 2: Match computation
    reg [DEPTH-1:0] match_results;
    reg valid_stage2;
    
    // Pre-computed masked data for faster comparison
    wire [WIDTH-1:0] masked_data_in;
    wire [WIDTH-1:0] masked_tcam_data [0:DEPTH-1];
    
    // Pre-compute masked input data
    assign masked_data_in = data_in_reg & mask_in_reg;
    
    // Generate pre-computed masked TCAM data
    genvar i;
    generate
        for (i = 0; i < DEPTH; i = i + 1) begin : gen_masked_tcam
            assign masked_tcam_data[i] = tcam_data[i] & tcam_mask[i];
        end
    endgenerate
    
    // Write logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset logic
        end else if (write_en) begin
            tcam_data[write_addr] <= write_data;
            tcam_mask[write_addr] <= write_mask;
        end
    end
    
    // Pipeline stage 1: Input registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_reg <= 0;
            mask_in_reg <= 0;
            valid_stage1 <= 0;
        end else begin
            data_in_reg <= data_in;
            mask_in_reg <= mask_in;
            valid_stage1 <= valid_in;
        end
    end
    
    // Pipeline stage 2: Match computation with balanced logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            match_results <= 0;
            valid_stage2 <= 0;
        end else begin
            valid_stage2 <= valid_stage1;
            
            if (valid_stage1) begin
                for (integer i = 0; i < DEPTH; i = i + 1) begin
                    // Simplified comparison using pre-computed masked values
                    match_results[i] <= (masked_data_in == masked_tcam_data[i]);
                end
            end
        end
    end
    
    // Output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hit_lines <= 0;
            valid_out <= 0;
        end else begin
            hit_lines <= match_results;
            valid_out <= valid_stage2;
        end
    end

endmodule