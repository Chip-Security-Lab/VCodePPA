//SystemVerilog
`timescale 1ns / 1ps
module pcm_codec #(parameter DATA_WIDTH = 16)
(
    input wire clk, rst_n, 
    input wire [DATA_WIDTH-1:0] pcm_in,     // PCM input samples
    input wire [7:0] compressed_in,         // Compressed input
    input wire encode_mode,                 // 1=encode, 0=decode
    input wire data_in_valid,               // Input data valid signal
    output reg [7:0] compressed_out,        // Compressed output
    output reg [DATA_WIDTH-1:0] pcm_out,    // PCM output samples
    output reg data_valid,                  // Output data valid
    output reg ready                        // Ready to accept new data
);
    // μ-law compression constants
    localparam BIAS = 33;
    localparam SEG_SHIFT = 4;
    
    // Handshaking signals for pipeline control
    reg stage1_ready, stage2_ready, stage2b_ready, stage3_ready, stage3b_ready;
    reg stage1_valid, stage2_valid, stage2b_valid, stage3_valid, stage3b_valid;
    
    // Pipeline stage 1 signals
    reg [DATA_WIDTH-1:0] abs_sample_stage1;
    reg sign_stage1;
    reg encode_mode_stage1;
    reg [7:0] compressed_in_stage1;
    
    // Pipeline stage 2 signals
    reg [DATA_WIDTH-1:0] abs_sample_stage2;
    reg sign_stage2;
    reg encode_mode_stage2;
    reg [3:0] segment_stage2;
    reg [7:0] compressed_in_stage2;
    
    // Pipeline stage 2b signals
    reg [DATA_WIDTH-1:0] abs_sample_stage2b;
    reg sign_stage2b;
    reg encode_mode_stage2b;
    reg [3:0] segment_stage2b;
    reg [7:0] compressed_in_stage2b;
    
    // Pipeline stage 3 signals
    reg sign_stage3;
    reg encode_mode_stage3;
    reg [3:0] segment_stage3;
    reg [2:0] step_stage3;
    reg [7:0] compressed_in_stage3;
    reg [DATA_WIDTH-1:0] abs_sample_stage3;
    
    // Additional pipeline stage for decode path
    reg sign_stage3b;
    reg [DATA_WIDTH-1:0] decode_value_stage3b;
    
    // Output stage registers
    reg [7:0] compressed_out_reg;
    reg [DATA_WIDTH-1:0] pcm_out_reg;
    reg data_valid_reg;
    
    // Pipeline buffer depth counter
    reg [2:0] buffer_depth;
    
    // Pipeline flow control
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            buffer_depth <= 3'd0;
            ready <= 1'b1;
        end else begin
            // Update buffer depth counter based on input and output activity
            if (data_in_valid && ready && !data_valid)
                buffer_depth <= buffer_depth + 1'b1;
            else if ((!data_in_valid || !ready) && data_valid)
                buffer_depth <= buffer_depth - 1'b1;
                
            // Ready signal control - can accept new data if not full
            ready <= (buffer_depth < 3'd5);
        end
    end
    
    // STAGE 1: Sample preparation and sign extraction
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            abs_sample_stage1 <= {DATA_WIDTH{1'b0}};
            sign_stage1 <= 1'b0;
            encode_mode_stage1 <= 1'b0;
            compressed_in_stage1 <= 8'h00;
            stage1_valid <= 1'b0;
        end else begin
            if (data_in_valid && ready) begin
                encode_mode_stage1 <= encode_mode;
                stage1_valid <= 1'b1;
                compressed_in_stage1 <= compressed_in;
                
                if (encode_mode) begin
                    // Extract sign and compute absolute value
                    sign_stage1 <= pcm_in[DATA_WIDTH-1];
                    abs_sample_stage1 <= pcm_in[DATA_WIDTH-1] ? (~pcm_in + 1'b1) : pcm_in;
                end else begin
                    sign_stage1 <= compressed_in[7];
                    abs_sample_stage1 <= {DATA_WIDTH{1'b0}}; // Will be set in later stages for decode
                end
            end else if (stage2_ready) begin
                // Clear valid flag when data is consumed by next stage
                stage1_valid <= 1'b0;
            end
        end
    end
    
    // STAGE 2: Segment calculation for encode / Extract segment for decode
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            abs_sample_stage2 <= {DATA_WIDTH{1'b0}};
            sign_stage2 <= 1'b0;
            encode_mode_stage2 <= 1'b0;
            segment_stage2 <= 4'h0;
            compressed_in_stage2 <= 8'h00;
            stage2_valid <= 1'b0;
            stage2_ready <= 1'b1;
        end else begin
            if (stage1_valid && stage2_ready) begin
                abs_sample_stage2 <= abs_sample_stage1;
                sign_stage2 <= sign_stage1;
                encode_mode_stage2 <= encode_mode_stage1;
                compressed_in_stage2 <= compressed_in_stage1;
                stage2_valid <= 1'b1;
                stage2_ready <= 1'b0;
                
                if (encode_mode_stage1) begin
                    // Calculate segment using priority encoder - split into two stages
                    if (abs_sample_stage1 < 128)
                        segment_stage2 <= 4'd0; // Temporary value, refined in next stage
                    else if (abs_sample_stage1 < 1024)
                        segment_stage2 <= 4'd1; // Temporary value, refined in next stage
                    else
                        segment_stage2 <= 4'd7;
                end else begin
                    // Decode: extract segment
                    segment_stage2 <= compressed_in_stage1[6:4];
                end
            end else if (stage2b_ready) begin
                // Data consumed by next stage
                stage2_valid <= 1'b0;
                stage2_ready <= 1'b1;
            end
        end
    end
    
    // New STAGE 2b: Pipeline register to break critical path in segment calculation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            abs_sample_stage2b <= {DATA_WIDTH{1'b0}};
            sign_stage2b <= 1'b0;
            encode_mode_stage2b <= 1'b0;
            segment_stage2b <= 4'h0;
            compressed_in_stage2b <= 8'h00;
            stage2b_valid <= 1'b0;
            stage2b_ready <= 1'b1;
        end else begin
            if (stage2_valid && stage2b_ready) begin
                abs_sample_stage2b <= abs_sample_stage2;
                sign_stage2b <= sign_stage2;
                encode_mode_stage2b <= encode_mode_stage2;
                compressed_in_stage2b <= compressed_in_stage2;
                stage2b_valid <= 1'b1;
                stage2b_ready <= 1'b0;
                
                if (encode_mode_stage2) begin
                    // Refine segment calculation from previous stage
                    if (segment_stage2 == 4'd0) begin
                        // Fine-grain segment calculation for values < 128
                        if (abs_sample_stage2 < 16)
                            segment_stage2b <= 4'd0;
                        else if (abs_sample_stage2 < 32)
                            segment_stage2b <= 4'd1;
                        else if (abs_sample_stage2 < 64)
                            segment_stage2b <= 4'd2;
                        else
                            segment_stage2b <= 4'd3;
                    end else if (segment_stage2 == 4'd1) begin
                        // Fine-grain segment calculation for values < 1024
                        if (abs_sample_stage2 < 256)
                            segment_stage2b <= 4'd4;
                        else if (abs_sample_stage2 < 512)
                            segment_stage2b <= 4'd5;
                        else
                            segment_stage2b <= 4'd6;
                    end else begin
                        segment_stage2b <= segment_stage2; // Already 7
                    end
                end else begin
                    segment_stage2b <= segment_stage2; // Pass through for decode
                end
            end else if (stage3_ready) begin
                // Data consumed by next stage
                stage2b_valid <= 1'b0;
                stage2b_ready <= 1'b1;
            end
        end
    end
    
    // STAGE 3: Calculate step within segment for encode / Prepare decode calculation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sign_stage3 <= 1'b0;
            encode_mode_stage3 <= 1'b0;
            segment_stage3 <= 4'h0;
            step_stage3 <= 3'h0;
            compressed_in_stage3 <= 8'h00;
            abs_sample_stage3 <= {DATA_WIDTH{1'b0}};
            stage3_valid <= 1'b0;
            stage3_ready <= 1'b1;
        end else begin
            if (stage2b_valid && stage3_ready) begin
                sign_stage3 <= sign_stage2b;
                encode_mode_stage3 <= encode_mode_stage2b;
                segment_stage3 <= segment_stage2b;
                compressed_in_stage3 <= compressed_in_stage2b;
                abs_sample_stage3 <= abs_sample_stage2b;
                stage3_valid <= 1'b1;
                stage3_ready <= 1'b0;
                
                if (encode_mode_stage2b) begin
                    // Calculate step within segment
                    case (segment_stage2b)
                        4'd0: step_stage3 <= abs_sample_stage2b[3:1];
                        4'd1: step_stage3 <= abs_sample_stage2b[4:2];
                        4'd2: step_stage3 <= abs_sample_stage2b[5:3];
                        4'd3: step_stage3 <= abs_sample_stage2b[6:4];
                        4'd4: step_stage3 <= abs_sample_stage2b[7:5];
                        4'd5: step_stage3 <= abs_sample_stage2b[8:6];
                        4'd6: step_stage3 <= abs_sample_stage2b[9:7];
                        4'd7: step_stage3 <= abs_sample_stage2b[10:8];
                        default: step_stage3 <= 3'h0;
                    endcase
                end else begin
                    // Decode: extract step
                    step_stage3 <= compressed_in_stage2b[3:1];
                end
            end else if (stage3b_ready || (stage3_valid && encode_mode_stage3)) begin
                // Data consumed by next stage or encode path
                stage3_valid <= 1'b0;
                stage3_ready <= 1'b1;
            end
        end
    end
    
    // STAGE 3b: Additional pipeline stage for decode path calculation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sign_stage3b <= 1'b0;
            decode_value_stage3b <= {DATA_WIDTH{1'b0}};
            stage3b_valid <= 1'b0;
            stage3b_ready <= 1'b1;
        end else begin
            if (stage3_valid && !encode_mode_stage3 && stage3b_ready) begin
                sign_stage3b <= sign_stage3;
                stage3b_valid <= 1'b1;
                stage3b_ready <= 1'b0;
                
                // Pre-calculate decode value to split critical path
                if (segment_stage3 == 4'd0)
                    decode_value_stage3b <= (({1'b1, step_stage3, 1'b1}) << 1) + BIAS;
                else
                    decode_value_stage3b <= (({1'b1, step_stage3, 1'b1}) << segment_stage3) + BIAS;
            end else if (stage3b_valid) begin
                // Data consumed by output stage
                stage3b_valid <= 1'b0;
                stage3b_ready <= 1'b1;
            end
        end
    end
    
    // STAGE 4: Final output calculation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            compressed_out <= 8'h00;
            pcm_out <= {DATA_WIDTH{1'b0}};
            data_valid <= 1'b0;
            compressed_out_reg <= 8'h00;
            pcm_out_reg <= {DATA_WIDTH{1'b0}};
            data_valid_reg <= 1'b0;
        end else begin
            // Registering outputs for better timing
            compressed_out <= compressed_out_reg;
            pcm_out <= pcm_out_reg;
            data_valid <= data_valid_reg;
            
            // Clear data_valid_reg when no valid data
            if (!(stage3_valid && encode_mode_stage3) && !stage3b_valid)
                data_valid_reg <= 1'b0;
                
            if (stage3_valid && encode_mode_stage3) begin
                // Encode final output (8-bit compressed data)
                compressed_out_reg <= {sign_stage3, ~segment_stage3[2:0], ~step_stage3};
                data_valid_reg <= 1'b1;
            end else if (stage3b_valid) begin
                // Apply sign to pre-calculated decode value
                if (sign_stage3b)
                    pcm_out_reg <= ~decode_value_stage3b + 1'b1;
                else
                    pcm_out_reg <= decode_value_stage3b;
                data_valid_reg <= 1'b1;
            end
        end
    end
    
    // Forward stall signals for backpressure
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Initialize all stage ready signals
            stage1_ready <= 1'b1;
            stage2_ready <= 1'b1;
            stage2b_ready <= 1'b1;
            stage3_ready <= 1'b1;
            stage3b_ready <= 1'b1;
        end else begin
            // Propagate backpressure when pipeline stalls
            if (!ready)
                stage1_ready <= 1'b0;
            else
                stage1_ready <= 1'b1;
        end
    end
endmodule