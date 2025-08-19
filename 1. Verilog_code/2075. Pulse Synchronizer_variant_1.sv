//SystemVerilog
module pulse_sync (
    input  wire src_clk,
    input  wire dst_clk,
    input  wire rst_n,
    input  wire pulse_in,
    output wire pulse_out
);

    // Stage 1: Source domain pulse edge toggler and valid pipeline
    reg toggle_src_stage1;
    reg valid_src_stage1;
    always @(posedge src_clk or negedge rst_n) begin
        if (!rst_n) begin
            toggle_src_stage1 <= 1'b0;
            valid_src_stage1  <= 1'b0;
        end else if (pulse_in) begin
            toggle_src_stage1 <= ~toggle_src_stage1;
            valid_src_stage1  <= 1'b1;
        end else begin
            valid_src_stage1  <= 1'b0;
        end
    end

    // Stage 2: CDC pipeline registers (src -> dst)
    reg toggle_cdc_stage2, toggle_cdc_stage3;
    reg valid_cdc_stage2, valid_cdc_stage3;
    always @(posedge dst_clk or negedge rst_n) begin
        if (!rst_n) begin
            toggle_cdc_stage2 <= 1'b0;
            toggle_cdc_stage3 <= 1'b0;
            valid_cdc_stage2  <= 1'b0;
            valid_cdc_stage3  <= 1'b0;
        end else begin
            toggle_cdc_stage2 <= toggle_src_stage1;
            valid_cdc_stage2  <= valid_src_stage1;
            toggle_cdc_stage3 <= toggle_cdc_stage2;
            valid_cdc_stage3  <= valid_cdc_stage2;
        end
    end

    // Stage 3: Synchronizer pipeline
    reg [1:0] sync_stage4;
    reg [1:0] valid_stage4;
    always @(posedge dst_clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_stage4  <= 2'b00;
            valid_stage4 <= 2'b00;
        end else begin
            sync_stage4[1]  <= sync_stage4[0];
            sync_stage4[0]  <= toggle_cdc_stage3;
            valid_stage4[1] <= valid_stage4[0];
            valid_stage4[0] <= valid_cdc_stage3;
        end
    end

    // Stage 4: Edge detector and output pipeline
    reg pulse_out_stage5;
    reg valid_stage5;
    always @(posedge dst_clk or negedge rst_n) begin
        if (!rst_n) begin
            pulse_out_stage5 <= 1'b0;
            valid_stage5     <= 1'b0;
        end else begin
            pulse_out_stage5 <= sync_stage4[1] ^ sync_stage4[0];
            valid_stage5     <= valid_stage4[1];
        end
    end

    // Output assignment using explicit multiplexer
    reg pulse_out_mux;
    always @(*) begin
        case (valid_stage5)
            1'b1: pulse_out_mux = pulse_out_stage5;
            1'b0: pulse_out_mux = 1'b0;
            default: pulse_out_mux = 1'b0;
        endcase
    end

    assign pulse_out = pulse_out_mux;

endmodule