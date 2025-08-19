//SystemVerilog
// Top level module
module AsymCompress #(
    parameter IN_W  = 64,
    parameter OUT_W = 32
) (
    input  logic               clk,
    input  logic               rst_n,
    input  logic [IN_W-1:0]    din,
    input  logic               din_valid,
    output logic [OUT_W-1:0]   dout,
    output logic               dout_valid
);
    // Calculate number of segments and pipeline stages
    localparam NUM_SEGMENTS = IN_W/OUT_W;
    localparam PIPE_STAGES = (NUM_SEGMENTS > 4) ? 2 : 1;
    
    // Segment extraction stage
    logic [OUT_W-1:0] segment_data [0:NUM_SEGMENTS-1];
    logic segment_valid;
    
    // Pipeline registers for segment data
    logic [OUT_W-1:0] segment_data_reg [0:NUM_SEGMENTS-1];
    logic segment_valid_reg;
    
    // XOR compression datapath
    logic [OUT_W-1:0] xor_results [0:NUM_SEGMENTS-1];
    logic [OUT_W-1:0] xor_stage1 [0:(NUM_SEGMENTS+1)/2-1];
    logic xor_stage1_valid;
    
    // Final pipeline stage
    logic [OUT_W-1:0] final_result;
    logic final_valid;
    
    // Extract segments from input data
    genvar i;
    generate
        for (i = 0; i < NUM_SEGMENTS; i = i + 1) begin : segment_extractors
            assign segment_data[i] = din[i*OUT_W +: OUT_W];
        end
    endgenerate
    
    // Stage 1: Register segment data
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            segment_valid_reg <= 1'b0;
            for (int j = 0; j < NUM_SEGMENTS; j = j + 1) begin
                segment_data_reg[j] <= '0;
            end
        end else begin
            segment_valid_reg <= din_valid;
            for (int j = 0; j < NUM_SEGMENTS; j = j + 1) begin
                segment_data_reg[j] <= segment_data[j];
            end
        end
    end
    
    // Stage 2: First level of XOR compression
    generate
        if (NUM_SEGMENTS == 1) begin : single_segment
            assign xor_stage1[0] = segment_data_reg[0];
        end else begin : multiple_segments
            for (i = 0; i < NUM_SEGMENTS/2; i = i + 1) begin : xor_pairs
                assign xor_stage1[i] = segment_data_reg[i*2] ^ segment_data_reg[i*2+1];
            end
            
            // Handle odd number of segments
            if (NUM_SEGMENTS % 2 == 1) begin : odd_segment
                assign xor_stage1[NUM_SEGMENTS/2] = segment_data_reg[NUM_SEGMENTS-1];
            end
        end
    endgenerate
    
    // Register first XOR stage results
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            xor_stage1_valid <= 1'b0;
            for (int j = 0; j < (NUM_SEGMENTS+1)/2; j = j + 1) begin
                xor_results[j] <= '0;
            end
        end else begin
            xor_stage1_valid <= segment_valid_reg;
            for (int j = 0; j < (NUM_SEGMENTS+1)/2; j = j + 1) begin
                xor_results[j] <= xor_stage1[j];
            end
        end
    end
    
    // Stage 3: Final XOR reduction
    always_comb begin
        final_result = xor_results[0];
        for (int j = 1; j < (NUM_SEGMENTS+1)/2; j = j + 1) begin
            final_result = final_result ^ xor_results[j];
        end
    end
    
    // Final output registers
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dout <= '0;
            dout_valid <= 1'b0;
        end else begin
            dout <= final_result;
            dout_valid <= xor_stage1_valid;
        end
    end
    
endmodule