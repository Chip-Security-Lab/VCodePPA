//SystemVerilog
module usb_frame_counter (
    input wire clk,
    input wire rst_n,
    
    // AXI-Stream Input interface
    input wire [10:0] s_axis_tdata,     // Contains frame_number
    input wire s_axis_tvalid,           // Replaces sof_valid
    output reg s_axis_tready,           // Replaces sof_ready
    input wire s_axis_tlast,            // Indicates frame_error
    
    // AXI-Stream Output interface
    output reg [31:0] m_axis_tdata,     // Contains expected_frame, frame_missed, frame_mismatch, sof_count, error_count
    output reg m_axis_tvalid,           // Replaces frame_data_valid
    input wire m_axis_tready,           // Replaces frame_data_ready
    output reg m_axis_tlast,            // End of transaction indicator
    
    // Status signals
    output wire [1:0] counter_status    // Kept as is for monitoring
);
    localparam FRAME_NORMAL = 1'b0;
    localparam FRAME_ERROR = 1'b1;
    
    reg [15:0] consecutive_good;
    reg initialized;
    reg pending_output;
    
    // Internal registers to hold transaction data
    reg [10:0] expected_frame;
    reg frame_missed;
    reg frame_mismatch;
    reg [15:0] sof_count;
    reg [15:0] error_count;
    
    // Status output based on error counts
    assign counter_status = (error_count > 16'd10) ? 2'b11 :   // Critical errors
                           (error_count > 16'd0)  ? 2'b01 :   // Warning
                           2'b00;                             // Good
    
    // Han-Carlson adder signals
    wire [15:0] sof_count_next;
    wire [15:0] error_count_next;
    wire [15:0] consecutive_good_next;
    
    // Instantiate Han-Carlson adders
    han_carlson_adder16 sof_adder(
        .a(sof_count),
        .b(16'd1),
        .sum(sof_count_next)
    );
    
    han_carlson_adder16 error_adder(
        .a(error_count),
        .b(16'd1),
        .sum(error_count_next)
    );
    
    han_carlson_adder16 consecutive_adder(
        .a(consecutive_good),
        .b(16'd1),
        .sum(consecutive_good_next)
    );
    
    // Internal signals for frame processing
    reg frame_mismatch_i, frame_missed_i;
    reg [10:0] expected_frame_i;
    reg [15:0] sof_count_i, error_count_i, consecutive_good_i;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            expected_frame <= 11'd0;
            expected_frame_i <= 11'd0;
            frame_missed <= 1'b0;
            frame_missed_i <= 1'b0;
            frame_mismatch <= 1'b0;
            frame_mismatch_i <= 1'b0;
            sof_count <= 16'd0;
            sof_count_i <= 16'd0;
            error_count <= 16'd0;
            error_count_i <= 16'd0;
            consecutive_good <= 16'd0;
            consecutive_good_i <= 16'd0;
            initialized <= 1'b0;
            
            // AXI-Stream handshake signals
            s_axis_tready <= 1'b1;
            m_axis_tvalid <= 1'b0;
            m_axis_tlast <= 1'b0;
            m_axis_tdata <= 32'd0;
            pending_output <= 1'b0;
        end else begin
            // Default single-cycle flags
            frame_missed_i <= 1'b0;
            frame_mismatch_i <= 1'b0;
            
            // Handle input AXI-Stream handshake
            if (s_axis_tvalid && s_axis_tready) begin
                s_axis_tready <= 1'b0;
                sof_count_i <= sof_count_next;
                
                if (s_axis_tlast) begin
                    // Frame error indicated by TLAST
                    error_count_i <= error_count_next;
                    consecutive_good_i <= 16'd0;
                end else if (!initialized) begin
                    // First SOF received - initialize expected counter
                    expected_frame_i <= s_axis_tdata;
                    initialized <= 1'b1;
                    consecutive_good_i <= 16'd1;
                end else begin
                    // Check if received frame matches expected
                    if (s_axis_tdata != expected_frame) begin
                        frame_mismatch_i <= 1'b1;
                        error_count_i <= error_count_next;
                        consecutive_good_i <= 16'd0;
                    end else begin
                        consecutive_good_i <= consecutive_good_next;
                    end
                    
                    // Update expected frame for next SOF
                    expected_frame_i <= (s_axis_tdata + 11'd1) & 11'h7FF;
                end
                
                pending_output <= 1'b1;
            end
            
            // Handle output AXI-Stream handshake
            if (pending_output && !m_axis_tvalid) begin
                m_axis_tvalid <= 1'b1;
                m_axis_tlast <= 1'b1; // Mark end of transaction
                
                // Pack all data into 32-bit TDATA
                m_axis_tdata <= {
                    sof_count_i[15:0],          // Bits 31:16
                    error_count_i[2:0],        // Bits 15:13
                    frame_mismatch_i,           // Bit 12
                    frame_missed_i,             // Bit 11
                    expected_frame_i[10:0]      // Bits 10:0
                };
                
                expected_frame <= expected_frame_i;
                frame_missed <= frame_missed_i;
                frame_mismatch <= frame_mismatch_i;
                sof_count <= sof_count_i;
                error_count <= error_count_i;
                consecutive_good <= consecutive_good_i;
            end
            
            if (m_axis_tvalid && m_axis_tready) begin
                m_axis_tvalid <= 1'b0;
                m_axis_tlast <= 1'b0;
                pending_output <= 1'b0;
                s_axis_tready <= 1'b1;
            end
        end
    end
endmodule

// Han-Carlson prefix adder (16-bit)
module han_carlson_adder16(
    input [15:0] a,
    input [15:0] b,
    output [15:0] sum
);
    // ... existing code ...
    // Preprocessing - Generate and Propagate signals
    wire [15:0] g, p;
    wire [15:0] g_out, p_out;
    
    // Step 1: Generate propagate and generate signals
    assign p = a ^ b;
    assign g = a & b;
    
    // Step 2: Perform prefix computation using Han-Carlson pattern
    // First stage - even bits
    wire [7:0] g_even_1, p_even_1;
    genvar i;
    
    generate
        for (i = 0; i < 8; i = i + 1) begin: stage1_even
            prefix_op prefix_s1_even(
                .g_i(g[2*i]),
                .p_i(p[2*i]),
                .g_j(g[2*i+1]),
                .p_j(p[2*i+1]),
                .g_out(g_even_1[i]),
                .p_out(p_even_1[i])
            );
        end
    endgenerate
    
    // Second stage and beyond
    wire [7:0] g_even_2, p_even_2;
    wire [7:0] g_even_3, p_even_3;
    wire [7:0] g_even_4, p_even_4;
    
    // Stage 2 (distance 2)
    generate
        for (i = 0; i < 7; i = i + 1) begin: stage2_even
            prefix_op prefix_s2_even(
                .g_i(g_even_1[i]),
                .p_i(p_even_1[i]),
                .g_j(g_even_1[i+1]),
                .p_j(p_even_1[i+1]),
                .g_out(g_even_2[i]),
                .p_out(p_even_2[i])
            );
        end
    endgenerate
    assign g_even_2[7] = g_even_1[7];
    assign p_even_2[7] = p_even_1[7];
    
    // Stage 3 (distance 4)
    generate
        for (i = 0; i < 5; i = i + 1) begin: stage3_even
            prefix_op prefix_s3_even(
                .g_i(g_even_2[i]),
                .p_i(p_even_2[i]),
                .g_j(g_even_2[i+2]),
                .p_j(p_even_2[i+2]),
                .g_out(g_even_3[i]),
                .p_out(p_even_3[i])
            );
        end
    endgenerate
    assign g_even_3[5] = g_even_2[5];
    assign p_even_3[5] = p_even_2[5];
    assign g_even_3[6] = g_even_2[6];
    assign p_even_3[6] = p_even_2[6];
    assign g_even_3[7] = g_even_2[7];
    assign p_even_3[7] = p_even_2[7];
    
    // Stage 4 (distance 8 - only needed for 16-bit or larger)
    generate
        for (i = 0; i < 1; i = i + 1) begin: stage4_even
            prefix_op prefix_s4_even(
                .g_i(g_even_3[i]),
                .p_i(p_even_3[i]),
                .g_j(g_even_3[i+4]),
                .p_j(p_even_3[i+4]),
                .g_out(g_even_4[i]),
                .p_out(p_even_4[i])
            );
        end
    endgenerate
    assign g_even_4[1] = g_even_3[1];
    assign p_even_4[1] = p_even_3[1];
    assign g_even_4[2] = g_even_3[2];
    assign p_even_4[2] = p_even_3[2];
    assign g_even_4[3] = g_even_3[3];
    assign p_even_4[3] = p_even_3[3];
    assign g_even_4[4] = g_even_3[4];
    assign p_even_4[4] = p_even_3[4];
    assign g_even_4[5] = g_even_3[5];
    assign p_even_4[5] = p_even_3[5];
    assign g_even_4[6] = g_even_3[6];
    assign p_even_4[6] = p_even_3[6];
    assign g_even_4[7] = g_even_3[7];
    assign p_even_4[7] = p_even_3[7];
    
    // Final stage - calculate odd positions using adjacent even position results
    wire [15:0] carry;
    
    // Carry for position 0 is always 0
    assign carry[0] = 1'b0;
    
    // Even positions get carries from the prefix network
    assign carry[2] = g_even_4[0];
    assign carry[4] = g_even_4[1];
    assign carry[6] = g_even_4[2];
    assign carry[8] = g_even_4[3];
    assign carry[10] = g_even_4[4];
    assign carry[12] = g_even_4[5];
    assign carry[14] = g_even_4[6];
    
    // Odd positions get their carries from a final prefix calculation
    generate
        for (i = 0; i < 8; i = i + 1) begin: final_odd
            if (i == 0) begin
                assign carry[2*i+1] = g[2*i];
            end else begin
                prefix_op prefix_odd(
                    .g_i(g_even_4[i-1]),
                    .p_i(p_even_4[i-1]),
                    .g_j(g[2*i]),
                    .p_j(p[2*i]),
                    .g_out(carry[2*i+1]),
                    .p_out()  // not needed
                );
            end
        end
    endgenerate
    
    // Final sum calculation
    assign sum = p ^ {carry[14:0], 1'b0};
endmodule

// Prefix operation module (black cell): g_out = g_i + p_i·g_j
module prefix_op(
    input g_i,
    input p_i,
    input g_j,
    input p_j,
    output g_out,
    output p_out
);
    assign g_out = g_i | (p_i & g_j);
    assign p_out = p_i & p_j;
endmodule