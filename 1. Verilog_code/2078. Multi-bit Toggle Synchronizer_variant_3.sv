//SystemVerilog
module multibit_toggle_sync_pipeline #(parameter WIDTH = 4) (
    input wire src_clk, 
    input wire dst_clk, 
    input wire reset,
    input wire [WIDTH-1:0] data_src,
    input wire update,
    output reg [WIDTH-1:0] data_dst
);

    // ---------- Stage 1: Source Domain Capture ----------
    reg toggle_src_stage1;
    reg [WIDTH-1:0] data_captured_stage1;
    reg valid_stage1;
    
    always @(posedge src_clk) begin
        if (reset) begin
            toggle_src_stage1 <= 1'b0;
            data_captured_stage1 <= {WIDTH{1'b0}};
            valid_stage1 <= 1'b0;
        end else if (update) begin
            toggle_src_stage1 <= ~toggle_src_stage1;
            data_captured_stage1 <= data_src;
            valid_stage1 <= 1'b1;
        end else begin
            valid_stage1 <= 1'b0;
        end
    end

    // ---------- Stage 2: Synchronize toggle and valid to destination clock ----------
    reg [2:0] toggle_sync_stage2;
    reg [2:0] valid_sync_stage2;
    reg [WIDTH-1:0] data_captured_stage2;
    reg [WIDTH-1:0] data_captured_stage3;
    
    // Double-register data capture to align with toggle
    always @(posedge dst_clk) begin
        if (reset) begin
            data_captured_stage2 <= {WIDTH{1'b0}};
            data_captured_stage3 <= {WIDTH{1'b0}};
        end else begin
            data_captured_stage2 <= data_captured_stage1;
            data_captured_stage3 <= data_captured_stage2;
        end
    end

    // Synchronize toggle and valid
    always @(posedge dst_clk) begin
        if (reset) begin
            toggle_sync_stage2 <= 3'b000;
            valid_sync_stage2 <= 3'b000;
        end else begin
            toggle_sync_stage2 <= {toggle_sync_stage2[1:0], toggle_src_stage1};
            valid_sync_stage2 <= {valid_sync_stage2[1:0], valid_stage1};
        end
    end

    // ---------- Stage 3: Output Register and Pipeline Valid Control ----------
    reg [WIDTH-1:0] data_dst_stage3;
    reg valid_stage3;
    reg toggle_last_stage3;

    // 3-bit borrow subtractor instance signals for edge detection
    wire borrow_out;
    wire [2:0] toggle_sub_result;
    reg [2:0] toggle_sync_stage2_3bit;
    reg [2:0] toggle_last_stage3_3bit;

    always @(posedge dst_clk) begin
        if (reset) begin
            toggle_sync_stage2_3bit <= 3'b000;
            toggle_last_stage3_3bit <= 3'b000;
        end else begin
            toggle_sync_stage2_3bit <= toggle_sync_stage2;
            toggle_last_stage3_3bit <= {2'b00, toggle_last_stage3};
        end
    end

    // 3-bit borrow subtractor for toggle detection
    borrow_subtractor_3bit u_borrow_sub (
        .minuend(toggle_sync_stage2_3bit),
        .subtrahend(toggle_last_stage3_3bit),
        .diff(toggle_sub_result),
        .borrow_out(borrow_out)
    );

    // Valid edge detect and output register
    always @(posedge dst_clk) begin
        if (reset) begin
            data_dst_stage3 <= {WIDTH{1'b0}};
            valid_stage3 <= 1'b0;
            toggle_last_stage3 <= 1'b0;
        end else begin
            // Data toggle detection using borrow subtractor
            if ((toggle_sub_result != 3'b000) && valid_sync_stage2[2]) begin
                data_dst_stage3 <= data_captured_stage3;
                valid_stage3 <= 1'b1;
                toggle_last_stage3 <= toggle_sync_stage2[2];
            end else begin
                valid_stage3 <= 1'b0;
            end
        end
    end

    // ---------- Stage 4: Output Assignment ----------
    always @(posedge dst_clk) begin
        if (reset) begin
            data_dst <= {WIDTH{1'b0}};
        end else if (valid_stage3) begin
            data_dst <= data_dst_stage3;
        end
    end

endmodule

// ----------- 3-bit Borrow Subtractor Module -----------
module borrow_subtractor_3bit (
    input  wire [2:0] minuend,
    input  wire [2:0] subtrahend,
    output wire [2:0] diff,
    output wire borrow_out
);
    wire [2:0] borrow;

    // Bit 0
    assign diff[0] = minuend[0] ^ subtrahend[0];
    assign borrow[0] = (~minuend[0]) & subtrahend[0];

    // Bit 1
    assign diff[1] = minuend[1] ^ subtrahend[1] ^ borrow[0];
    assign borrow[1] = ((~minuend[1]) & (subtrahend[1] | borrow[0])) | (subtrahend[1] & borrow[0]);

    // Bit 2
    assign diff[2] = minuend[2] ^ subtrahend[2] ^ borrow[1];
    assign borrow[2] = ((~minuend[2]) & (subtrahend[2] | borrow[1])) | (subtrahend[2] & borrow[1]);

    assign borrow_out = borrow[2];
endmodule