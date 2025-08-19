//SystemVerilog
module strobe_sync (
    input wire clk_a,
    input wire clk_b,
    input wire reset,
    input wire data_a,
    input wire strobe_a,
    output reg data_b,
    output reg strobe_b
);
    // Source domain registers
    reg data_a_captured_stage1;
    reg data_a_captured_stage2;
    reg toggle_a_stage1, toggle_a_stage2;

    // Destination domain registers (deeper pipeline)
    reg toggle_a_meta_stage1, toggle_a_meta_stage2;
    reg toggle_a_sync_stage1, toggle_a_sync_stage2;
    reg toggle_a_delay_stage1, toggle_a_delay_stage2;
    reg data_b_stage1, data_b_stage2;
    reg strobe_b_stage1, strobe_b_stage2;

    // Source domain: Pipeline stage 1 - capture data and toggle
    always @(posedge clk_a) begin
        if (reset) begin
            data_a_captured_stage1 <= 1'b0;
            toggle_a_stage1 <= 1'b0;
        end else if (strobe_a) begin
            data_a_captured_stage1 <= data_a;
            toggle_a_stage1 <= ~toggle_a_stage1;
        end else begin
            data_a_captured_stage1 <= data_a_captured_stage1;
            toggle_a_stage1 <= toggle_a_stage1;
        end
    end

    // Source domain: Pipeline stage 2 - register outputs
    always @(posedge clk_a) begin
        if (reset) begin
            data_a_captured_stage2 <= 1'b0;
            toggle_a_stage2 <= 1'b0;
        end else begin
            data_a_captured_stage2 <= data_a_captured_stage1;
            toggle_a_stage2 <= toggle_a_stage1;
        end
    end

    // Destination domain: Pipeline stage 1 - first metastability filter
    always @(posedge clk_b) begin
        if (reset) begin
            toggle_a_meta_stage1 <= 1'b0;
        end else begin
            toggle_a_meta_stage1 <= toggle_a_stage2;
        end
    end

    // Destination domain: Pipeline stage 2 - second metastability filter
    always @(posedge clk_b) begin
        if (reset) begin
            toggle_a_meta_stage2 <= 1'b0;
        end else begin
            toggle_a_meta_stage2 <= toggle_a_meta_stage1;
        end
    end

    // Destination domain: Pipeline stage 3 - synchronize toggle
    always @(posedge clk_b) begin
        if (reset) begin
            toggle_a_sync_stage1 <= 1'b0;
        end else begin
            toggle_a_sync_stage1 <= toggle_a_meta_stage2;
        end
    end

    // Destination domain: Pipeline stage 4 - synchronize toggle (extra stage for higher Fmax)
    always @(posedge clk_b) begin
        if (reset) begin
            toggle_a_sync_stage2 <= 1'b0;
        end else begin
            toggle_a_sync_stage2 <= toggle_a_sync_stage1;
        end
    end

    // Destination domain: Pipeline stage 5 - delay toggle for edge detection
    always @(posedge clk_b) begin
        if (reset) begin
            toggle_a_delay_stage1 <= 1'b0;
        end else begin
            toggle_a_delay_stage1 <= toggle_a_sync_stage2;
        end
    end

    // Destination domain: Pipeline stage 6 - extra delay stage
    always @(posedge clk_b) begin
        if (reset) begin
            toggle_a_delay_stage2 <= 1'b0;
        end else begin
            toggle_a_delay_stage2 <= toggle_a_delay_stage1;
        end
    end

    // Destination domain: Pipeline stage 7 - strobe generation
    always @(posedge clk_b) begin
        if (reset) begin
            strobe_b_stage1 <= 1'b0;
        end else begin
            strobe_b_stage1 <= toggle_a_sync_stage2 ^ toggle_a_delay_stage2;
        end
    end

    // Destination domain: Pipeline stage 8 - register strobe (final stage)
    always @(posedge clk_b) begin
        if (reset) begin
            strobe_b_stage2 <= 1'b0;
        end else begin
            strobe_b_stage2 <= strobe_b_stage1;
        end
    end

    // Destination domain: Pipeline stage 9 - data capture
    always @(posedge clk_b) begin
        if (reset) begin
            data_b_stage1 <= 1'b0;
        end else if (strobe_b_stage1) begin
            data_b_stage1 <= data_a_captured_stage2;
        end else begin
            data_b_stage1 <= data_b_stage1;
        end
    end

    // Destination domain: Pipeline stage 10 - final data output register
    always @(posedge clk_b) begin
        if (reset) begin
            data_b_stage2 <= 1'b0;
        end else begin
            data_b_stage2 <= data_b_stage1;
        end
    end

    // Output assignment
    always @(posedge clk_b) begin
        if (reset) begin
            data_b <= 1'b0;
            strobe_b <= 1'b0;
        end else begin
            data_b <= data_b_stage2;
            strobe_b <= strobe_b_stage2;
        end
    end

endmodule