//SystemVerilog
module enabled_reset_sync_axi_stream (
    input  wire        aclk,
    input  wire        aresetn,
    input  wire        enable,
    output wire [0:0]  m_axis_tdata,
    output wire        m_axis_tvalid,
    input  wire        m_axis_tready,
    output wire        m_axis_tlast
);

    // Stage 1: Synchronize enable, metastable logic
    reg enable_stage1;
    reg metastable_stage1;

    // Stage 2: Additional pipeline for metastable and rst_out_n
    reg metastable_stage2;
    reg rst_out_n_stage2;

    // Stage 3: tvalid and tlast pipeline
    reg tvalid_stage3;
    reg tlast_stage3;

    // Stage 4: Output registers
    reg tvalid_stage4;
    reg tlast_stage4;

    // Pipeline for enable signal (to balance path)
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            enable_stage1      <= 1'b0;
        end else begin
            enable_stage1      <= enable;
        end
    end

    // Stage 1: Generate metastable_stage1
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            metastable_stage1  <= 1'b0;
        end else if (enable_stage1) begin
            metastable_stage1  <= 1'b1;
        end
    end

    // Stage 2: Pipeline metastable and rst_out_n
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            metastable_stage2  <= 1'b0;
            rst_out_n_stage2   <= 1'b0;
        end else begin
            metastable_stage2  <= metastable_stage1;
            rst_out_n_stage2   <= metastable_stage2;
        end
    end

    // Stage 3: Generate tvalid and tlast with pipeline
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            tvalid_stage3      <= 1'b0;
            tlast_stage3       <= 1'b0;
        end else if (enable_stage1) begin
            tvalid_stage3      <= 1'b1;
            tlast_stage3       <= 1'b1;
        end else if (tvalid_stage3 && m_axis_tready) begin
            tvalid_stage3      <= 1'b0;
            tlast_stage3       <= 1'b0;
        end
    end

    // Stage 4: Output pipeline for tvalid and tlast
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            tvalid_stage4      <= 1'b0;
            tlast_stage4       <= 1'b0;
        end else begin
            tvalid_stage4      <= tvalid_stage3;
            tlast_stage4       <= tlast_stage3;
        end
    end

    assign m_axis_tdata  = rst_out_n_stage2;
    assign m_axis_tvalid = tvalid_stage4;
    assign m_axis_tlast  = tlast_stage4;

endmodule