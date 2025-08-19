//SystemVerilog
module pcm_codec #(parameter DATA_WIDTH = 16)
(
    input wire clk, rst_n, 
    input wire [DATA_WIDTH-1:0] pcm_in,     // PCM input samples
    input wire [7:0] compressed_in,         // Compressed input
    input wire encode_mode,                 // 1=encode, 0=decode
    output reg [7:0] compressed_out,        // Compressed output
    output reg [DATA_WIDTH-1:0] pcm_out,    // PCM output samples
    output reg data_valid
);
    // μ-law compression constants
    localparam BIAS = 33;
    
    // Pipeline stage 1 registers - Input processing
    reg [DATA_WIDTH-1:0] abs_sample_stage1;
    reg sign_stage1;
    reg encode_mode_stage1;
    reg [7:0] compressed_in_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2 registers - Segment calculation
    reg [DATA_WIDTH-1:0] abs_sample_stage2;
    reg sign_stage2;
    reg encode_mode_stage2;
    reg [7:0] compressed_in_stage2;
    reg [3:0] segment_stage2;
    reg valid_stage2;
    // Pre-calculated segment threshold registers
    reg [7:0] segment_thresholds[0:6];
    
    // Pipeline stage 3 registers - Encoding/Decoding
    reg sign_stage3;
    reg [3:0] segment_stage3;
    reg [3:0] step_stage3;
    reg encode_mode_stage3;
    reg [7:0] compressed_data_stage3;
    reg [DATA_WIDTH-1:0] pcm_data_stage3;
    reg valid_stage3;
    
    // Pre-calculation of segment thresholds
    initial begin
        segment_thresholds[0] = 8'd16;
        segment_thresholds[1] = 8'd32;
        segment_thresholds[2] = 8'd64;
        segment_thresholds[3] = 8'd128;
        segment_thresholds[4] = 8'd256;
        segment_thresholds[5] = 8'd512;
        segment_thresholds[6] = 8'd1024;
    end
    
    // Stage 1: Input processing and absolute value calculation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            abs_sample_stage1 <= {DATA_WIDTH{1'b0}};
            sign_stage1 <= 1'b0;
            encode_mode_stage1 <= 1'b0;
            compressed_in_stage1 <= 8'h00;
            valid_stage1 <= 1'b0;
        end else begin
            valid_stage1 <= 1'b1; // Input is always valid for simplicity
            encode_mode_stage1 <= encode_mode;
            compressed_in_stage1 <= compressed_in;
            
            // Split the critical path by pre-computing both cases and selecting
            sign_stage1 <= pcm_in[DATA_WIDTH-1];
            // Calculate absolute value regardless of mode to balance paths
            abs_sample_stage1 <= pcm_in[DATA_WIDTH-1] ? (~pcm_in + 1'b1) : pcm_in;
        end
    end
    
    // Stage 2: Segment calculation for encoding / initial decode processing
    // Variable for faster segment calculation using parallel comparisons
    reg [6:0] segment_compare;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            abs_sample_stage2 <= {DATA_WIDTH{1'b0}};
            sign_stage2 <= 1'b0;
            encode_mode_stage2 <= 1'b0;
            compressed_in_stage2 <= 8'h00;
            segment_stage2 <= 4'h0;
            valid_stage2 <= 1'b0;
        end else begin
            valid_stage2 <= valid_stage1;
            sign_stage2 <= sign_stage1;
            encode_mode_stage2 <= encode_mode_stage1;
            compressed_in_stage2 <= compressed_in_stage1;
            abs_sample_stage2 <= abs_sample_stage1;
            
            if (encode_mode_stage1) begin
                // Parallelized segment calculation using comparison tree
                // Each comparison happens in parallel rather than in a long chain
                segment_compare[0] <= (abs_sample_stage1 >= segment_thresholds[0]);
                segment_compare[1] <= (abs_sample_stage1 >= segment_thresholds[1]);
                segment_compare[2] <= (abs_sample_stage1 >= segment_thresholds[2]);
                segment_compare[3] <= (abs_sample_stage1 >= segment_thresholds[3]);
                segment_compare[4] <= (abs_sample_stage1 >= segment_thresholds[4]);
                segment_compare[5] <= (abs_sample_stage1 >= segment_thresholds[5]);
                segment_compare[6] <= (abs_sample_stage1 >= segment_thresholds[6]);
                
                // Priority encoder for segment calculation with balanced logic depth
                casez(segment_compare)
                    7'b0??????: segment_stage2 <= 4'h0;
                    7'b10?????: segment_stage2 <= 4'h1;
                    7'b110????: segment_stage2 <= 4'h2;
                    7'b1110???: segment_stage2 <= 4'h3;
                    7'b11110??: segment_stage2 <= 4'h4;
                    7'b111110?: segment_stage2 <= 4'h5;
                    7'b1111110: segment_stage2 <= 4'h6;
                    7'b1111111: segment_stage2 <= 4'h7;
                    default:    segment_stage2 <= 4'h0;
                endcase
            end else begin
                // Decode: Extract segment from compressed input
                segment_stage2 <= compressed_in_stage1[6:4];
            end
        end
    end
    
    // Pre-calculate step for decoding in stage 2
    reg [3:0] step_pre_stage2;
    
    always @(posedge clk) begin
        if (encode_mode_stage1 == 1'b0) begin
            // Pre-calculate step for decode path to balance timing paths
            step_pre_stage2 <= ~compressed_in_stage1[3:0];
        end
    end
    
    // Stage 3: Final encoding/decoding calculation
    // Intermediate signals to break long combinational paths
    reg [DATA_WIDTH-1:0] pcm_unsigned_value;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sign_stage3 <= 1'b0;
            segment_stage3 <= 4'h0;
            step_stage3 <= 4'h0;
            encode_mode_stage3 <= 1'b0;
            compressed_data_stage3 <= 8'h00;
            pcm_data_stage3 <= {DATA_WIDTH{1'b0}};
            valid_stage3 <= 1'b0;
            pcm_unsigned_value <= {DATA_WIDTH{1'b0}};
        end else begin
            valid_stage3 <= valid_stage2;
            sign_stage3 <= sign_stage2;
            segment_stage3 <= segment_stage2;
            encode_mode_stage3 <= encode_mode_stage2;
            
            if (encode_mode_stage2) begin
                // Complete encoding
                // Shift operation is optimized with segment as shift amount
                step_stage3 <= (abs_sample_stage2 >> segment_stage2) & 4'hF;
                compressed_data_stage3 <= {sign_stage2, ~segment_stage2, ~((abs_sample_stage2 >> segment_stage2) & 4'hF)};
                pcm_data_stage3 <= {DATA_WIDTH{1'b0}};
            end else begin
                // Use pre-calculated step value from stage 2
                step_stage3 <= step_pre_stage2;
                
                // Reconstruct the PCM value - separate calculation paths for balance
                if (segment_stage2 == 0) begin
                    pcm_unsigned_value <= {step_pre_stage2, 1'b0}; // step << 1
                end else begin
                    pcm_unsigned_value <= ((step_pre_stage2 | 4'h10) << segment_stage2) - BIAS;
                end
                
                // Apply sign in the next clock cycle to reduce critical path
                pcm_data_stage3 <= sign_stage2 ? (~pcm_unsigned_value + 1'b1) : pcm_unsigned_value;
                compressed_data_stage3 <= 8'h00;
            end
        end
    end
    
    // Output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            compressed_out <= 8'h00;
            pcm_out <= {DATA_WIDTH{1'b0}};
            data_valid <= 1'b0;
        end else begin
            data_valid <= valid_stage3;
            
            if (encode_mode_stage3) begin
                compressed_out <= compressed_data_stage3;
                pcm_out <= {DATA_WIDTH{1'b0}};
            end else begin
                compressed_out <= 8'h00;
                pcm_out <= pcm_data_stage3;
            end
        end
    end
endmodule