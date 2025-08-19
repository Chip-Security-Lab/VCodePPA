//SystemVerilog
module enc_8b10b_top #(parameter IMPLEMENT_TABLES = 1)
(
    input wire clk, reset_n,
    
    // AXI-Stream Input Interface
    input wire s_axis_tvalid,
    output wire s_axis_tready,
    input wire [8:0] s_axis_tdata,  // 8-bit data_in + 1-bit k_in
    input wire s_axis_tlast,
    
    // AXI-Stream Encoded Input Interface
    input wire encoded_axis_tvalid,
    output wire encoded_axis_tready,
    input wire [9:0] encoded_axis_tdata,
    input wire encoded_axis_tlast,
    
    // AXI-Stream Output Interface
    output wire m_axis_tvalid,
    input wire m_axis_tready,
    output wire [9:0] m_axis_tdata,
    output wire m_axis_tlast,
    
    // AXI-Stream Decoded Output Interface
    output wire decoded_axis_tvalid,
    input wire decoded_axis_tready,
    output wire [9:0] decoded_axis_tdata, // 8-bit data_out + 1-bit k_out + 1-bit error indicator
    output wire decoded_axis_tlast
);
    // Internal signals
    wire disp_state_feedback;
    wire [5:0] lut_5b6b_idx_stage1;
    wire [3:0] lut_3b4b_idx_stage1;
    wire k_in_stage1;
    wire [7:0] data_in_stage1;
    wire disp_state_stage1;
    
    wire [5:0] lut_5b6b_idx_stage2;
    wire [3:0] lut_3b4b_idx_stage2;
    wire disp_state_stage2;
    wire k_in_stage2;
    
    wire [5:0] encoded_5b_stage3;
    wire [3:0] encoded_3b_stage3;
    wire disp_state_stage3;
    
    wire [5:0] encoded_5b_stage4;
    wire [3:0] encoded_3b_stage4;
    wire disp_state_stage4;

    // Pipeline handshake signals
    wire stage1_ready, stage1_valid;
    wire stage2_ready, stage2_valid;
    wire stage3_ready, stage3_valid;
    wire stage4_ready, stage4_valid;
    wire decoder_ready, decoder_valid;
    
    // Extract data from AXI-Stream inputs
    wire k_in = s_axis_tdata[8];
    wire [7:0] data_in = s_axis_tdata[7:0];
    
    // Output registers
    reg [9:0] encoded_out;
    reg [7:0] data_out;
    reg k_out;
    reg disparity_err, code_err;
    
    // AXI-Stream flow control
    assign s_axis_tready = stage1_ready;
    assign encoded_axis_tready = decoder_ready;
    
    assign stage1_valid = s_axis_tvalid & stage1_ready;
    
    // AXI-Stream output control
    assign m_axis_tvalid = stage4_valid;
    assign m_axis_tdata = encoded_out;
    assign m_axis_tlast = s_axis_tlast; // Pass through last signal
    
    assign decoded_axis_tvalid = decoder_valid;
    assign decoded_axis_tdata = {disparity_err | code_err, k_out, data_out};
    assign decoded_axis_tlast = encoded_axis_tlast; // Pass through last signal
    
    // Stage ready/valid signals
    assign stage1_ready = !stage2_valid || stage2_ready;
    assign stage2_ready = !stage3_valid || stage3_ready;
    assign stage3_ready = !stage4_valid || stage4_ready;
    assign stage4_ready = !m_axis_tvalid || m_axis_tready;
    assign decoder_ready = !decoded_axis_tvalid || decoded_axis_tready;
    
    // Instantiate Stage 1 module: Input Registration and Initial Lookups with AXI-Stream
    enc_8b10b_stage1 stage1_inst (
        .clk(clk),
        .reset_n(reset_n),
        .enable(stage1_valid),
        .k_in(k_in),
        .data_in(data_in),
        .disp_state_feedback(disp_state_feedback),
        .lut_5b6b_idx_stage1(lut_5b6b_idx_stage1),
        .lut_3b4b_idx_stage1(lut_3b4b_idx_stage1),
        .k_in_stage1(k_in_stage1),
        .data_in_stage1(data_in_stage1),
        .disp_state_stage1(disp_state_stage1),
        .valid_out(stage2_valid)
    );
    
    // Instantiate Stage 2 module: Process Lookup Indices with AXI-Stream
    enc_8b10b_stage2 stage2_inst (
        .clk(clk),
        .reset_n(reset_n),
        .enable(stage2_valid && stage2_ready),
        .lut_5b6b_idx_stage1(lut_5b6b_idx_stage1),
        .lut_3b4b_idx_stage1(lut_3b4b_idx_stage1),
        .disp_state_stage1(disp_state_stage1),
        .k_in_stage1(k_in_stage1),
        .lut_5b6b_idx_stage2(lut_5b6b_idx_stage2),
        .lut_3b4b_idx_stage2(lut_3b4b_idx_stage2),
        .disp_state_stage2(disp_state_stage2),
        .k_in_stage2(k_in_stage2),
        .valid_out(stage3_valid)
    );
    
    // Instantiate Stage 3 module: Encoding Lookups with AXI-Stream
    enc_8b10b_stage3 #(
        .IMPLEMENT_TABLES(IMPLEMENT_TABLES)
    ) stage3_inst (
        .clk(clk),
        .reset_n(reset_n),
        .enable(stage3_valid && stage3_ready),
        .lut_5b6b_idx_stage2(lut_5b6b_idx_stage2),
        .lut_3b4b_idx_stage2(lut_3b4b_idx_stage2),
        .disp_state_stage2(disp_state_stage2),
        .k_in_stage2(k_in_stage2),
        .encoded_5b_stage3(encoded_5b_stage3),
        .encoded_3b_stage3(encoded_3b_stage3),
        .disp_state_stage3(disp_state_stage3),
        .valid_out(stage4_valid)
    );
    
    // Instantiate Stage 4 module: Final Encoding and Output with AXI-Stream
    enc_8b10b_stage4 stage4_inst (
        .clk(clk),
        .reset_n(reset_n),
        .enable(stage4_valid && stage4_ready),
        .encoded_5b_stage3(encoded_5b_stage3),
        .encoded_3b_stage3(encoded_3b_stage3),
        .disp_state_stage3(disp_state_stage3),
        .encoded_out(encoded_out),
        .encoded_5b_stage4(encoded_5b_stage4),
        .encoded_3b_stage4(encoded_3b_stage4),
        .disp_state_stage4(disp_state_stage4)
    );
    
    // Instantiate Decoder module with AXI-Stream
    enc_8b10b_decoder decoder_inst (
        .clk(clk),
        .reset_n(reset_n),
        .enable(encoded_axis_tvalid && decoder_ready),
        .encoded_in(encoded_axis_tdata),
        .data_out(data_out),
        .k_out(k_out),
        .disparity_err(disparity_err),
        .code_err(code_err),
        .valid_out(decoder_valid)
    );
    
    // Feedback connection
    assign disp_state_feedback = disp_state_stage4;
endmodule

// Stage 1: Input Registration and Initial Lookups with AXI-Stream support
module enc_8b10b_stage1 (
    input wire clk, reset_n, enable,
    input wire k_in,
    input wire [7:0] data_in,
    input wire disp_state_feedback,
    output reg [5:0] lut_5b6b_idx_stage1,
    output reg [3:0] lut_3b4b_idx_stage1,
    output reg k_in_stage1,
    output reg [7:0] data_in_stage1,
    output reg disp_state_stage1,
    output reg valid_out
);
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            lut_5b6b_idx_stage1 <= 6'b0;
            lut_3b4b_idx_stage1 <= 4'b0;
            k_in_stage1 <= 1'b0;
            data_in_stage1 <= 8'b0;
            disp_state_stage1 <= 1'b0;
            valid_out <= 1'b0;
        end else if (enable) begin
            // Register inputs
            k_in_stage1 <= k_in;
            data_in_stage1 <= data_in;
            disp_state_stage1 <= disp_state_feedback; // Use feedback from last stage
            
            // Prepare lookup indices
            lut_5b6b_idx_stage1 <= {k_in, data_in[4:0]};
            lut_3b4b_idx_stage1 <= {k_in, data_in[7:5]};
            
            // Signal data is valid for next stage
            valid_out <= 1'b1;
        end else if (valid_out) begin
            // Clear valid flag when data is consumed
            valid_out <= 1'b0;
        end
    end
endmodule

// Stage 2: Process Lookup Indices with AXI-Stream support
module enc_8b10b_stage2 (
    input wire clk, reset_n, enable,
    input wire [5:0] lut_5b6b_idx_stage1,
    input wire [3:0] lut_3b4b_idx_stage1,
    input wire disp_state_stage1,
    input wire k_in_stage1,
    output reg [5:0] lut_5b6b_idx_stage2,
    output reg [3:0] lut_3b4b_idx_stage2,
    output reg disp_state_stage2,
    output reg k_in_stage2,
    output reg valid_out
);
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            lut_5b6b_idx_stage2 <= 6'b0;
            lut_3b4b_idx_stage2 <= 4'b0;
            disp_state_stage2 <= 1'b0;
            k_in_stage2 <= 1'b0;
            valid_out <= 1'b0;
        end else if (enable) begin
            lut_5b6b_idx_stage2 <= lut_5b6b_idx_stage1;
            lut_3b4b_idx_stage2 <= lut_3b4b_idx_stage1;
            disp_state_stage2 <= disp_state_stage1;
            k_in_stage2 <= k_in_stage1;
            valid_out <= 1'b1;
        end else if (valid_out) begin
            // Clear valid flag when data is consumed
            valid_out <= 1'b0;
        end
    end
endmodule

// Stage 3: Perform Encoding Lookups with AXI-Stream support
module enc_8b10b_stage3 #(parameter IMPLEMENT_TABLES = 1)
(
    input wire clk, reset_n, enable,
    input wire [5:0] lut_5b6b_idx_stage2,
    input wire [3:0] lut_3b4b_idx_stage2,
    input wire disp_state_stage2,
    input wire k_in_stage2,
    output reg [5:0] encoded_5b_stage3,
    output reg [3:0] encoded_3b_stage3,
    output reg disp_state_stage3,
    output reg valid_out
);
    // 5b6b encoding tables could be implemented here
    reg [5:0] lut_5b6b_pos[0:31];  // Positive disparity table
    reg [5:0] lut_5b6b_neg[0:31];  // Negative disparity table
    
    // 3b4b encoding tables could be implemented here
    reg [3:0] lut_3b4b_pos[0:7];   // Positive disparity table
    reg [3:0] lut_3b4b_neg[0:7];   // Negative disparity table
    
    // Initialize tables if needed (would implement proper tables in real design)
    initial begin
        if (IMPLEMENT_TABLES) begin
            // These would be the actual 8b/10b encoding tables in a full implementation
        end
    end
    
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            encoded_5b_stage3 <= 6'b0;
            encoded_3b_stage3 <= 4'b0;
            disp_state_stage3 <= 1'b0;
            valid_out <= 1'b0;
        end else if (enable) begin
            // 5b/6b encoding lookup
            // This is a placeholder for the actual encoding logic using tables
            encoded_5b_stage3 <= lut_5b6b_idx_stage2;
            
            // 3b/4b encoding lookup
            // Depends on the current running disparity from stage 2
            encoded_3b_stage3 <= lut_3b4b_idx_stage2;
            
            // Update running disparity based on 5b/6b encoding
            // This is a placeholder for actual disparity calculation
            disp_state_stage3 <= disp_state_stage2;
            
            valid_out <= 1'b1;
        end else if (valid_out) begin
            // Clear valid flag when data is consumed
            valid_out <= 1'b0;
        end
    end
endmodule

// Stage 4: Final Encoding and Output with AXI-Stream support
module enc_8b10b_stage4 (
    input wire clk, reset_n, enable,
    input wire [5:0] encoded_5b_stage3,
    input wire [3:0] encoded_3b_stage3,
    input wire disp_state_stage3,
    output reg [9:0] encoded_out,
    output reg [5:0] encoded_5b_stage4,
    output reg [3:0] encoded_3b_stage4,
    output reg disp_state_stage4
);
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            encoded_5b_stage4 <= 6'b0;
            encoded_3b_stage4 <= 4'b0;
            disp_state_stage4 <= 1'b0;
            encoded_out <= 10'b0;
        end else if (enable) begin
            encoded_5b_stage4 <= encoded_5b_stage3;
            encoded_3b_stage4 <= encoded_3b_stage3;
            
            // Update running disparity based on 3b/4b encoding
            // This is a placeholder for actual disparity calculation
            disp_state_stage4 <= disp_state_stage3;
            
            // Combine 5b/6b and 3b/4b to form 10-bit output
            encoded_out <= {encoded_3b_stage3, encoded_5b_stage3};
        end
    end
endmodule

// Decoder module with AXI-Stream support
module enc_8b10b_decoder (
    input wire clk, reset_n, enable,
    input wire [9:0] encoded_in,
    output reg [7:0] data_out,
    output reg k_out,
    output reg disparity_err, code_err,
    output reg valid_out
);
    // Implements multi-stage decoding pipeline
    // Decoding lookup tables would be implemented here
    
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            data_out <= 8'b0;
            k_out <= 1'b0;
            disparity_err <= 1'b0;
            code_err <= 1'b0;
            valid_out <= 1'b0;
        end else if (enable) begin
            // Decoding logic would be implemented here in multiple stages
            // Placeholder for actual decoding pipeline implementation
            valid_out <= 1'b1;
        end else if (valid_out) begin
            // Clear valid flag when data is consumed
            valid_out <= 1'b0;
        end
    end
endmodule