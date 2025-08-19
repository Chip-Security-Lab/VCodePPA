//SystemVerilog
`timescale 1ns/1ps
module list2array_pipeline #(
    parameter DW = 8,
    parameter MAX_LEN = 8
)(
    input                   clk,
    input                   rst_n,
    input  [DW-1:0]         node_data,
    input                   node_valid,
    output [DW*MAX_LEN-1:0] array_out,
    output [3:0]            length,
    input                   flush,
    input                   start,
    output                  ready,
    output                  valid
);

    // Pipeline Stage 1: Input Capture
    reg  [DW-1:0]      node_data_stage1;
    reg                node_valid_stage1;
    reg                start_stage1, flush_stage1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            node_data_stage1 <= {DW{1'b0}};
            node_valid_stage1 <= 1'b0;
            start_stage1 <= 1'b0;
            flush_stage1 <= 1'b0;
        end else begin
            node_data_stage1 <= node_data;
            node_valid_stage1 <= node_valid;
            start_stage1 <= start;
            flush_stage1 <= flush;
        end
    end

    // Pipeline Stage 2: Indexing and Memory Write
    reg [DW-1:0]       node_data_stage2;
    reg                node_valid_stage2;
    reg                start_stage2, flush_stage2;
    reg [3:0]          idx_stage2, idx_reg_stage1;
    reg [3:0]          length_stage2, length_reg_stage1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            node_data_stage2 <= {DW{1'b0}};
            node_valid_stage2 <= 1'b0;
            start_stage2 <= 1'b0;
            flush_stage2 <= 1'b0;
            idx_stage2 <= 4'd0;
            length_stage2 <= 4'd0;
            idx_reg_stage1 <= 4'd0;
            length_reg_stage1 <= 4'd0;
        end else begin
            node_data_stage2 <= node_data_stage1;
            node_valid_stage2 <= node_valid_stage1;
            start_stage2 <= start_stage1;
            flush_stage2 <= flush_stage1;
            idx_stage2 <= idx_reg_stage1;
            length_stage2 <= length_reg_stage1;
        end
    end

    // Index and length registers (Stage 1, for use in Stage 2)
    reg [3:0]          idx_reg_stage0, length_reg_stage0;
    reg                ready_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            idx_reg_stage0 <= 4'd0;
            length_reg_stage0 <= 4'd0;
            ready_reg <= 1'b1;
        end else if (flush || flush_stage1 || flush_stage2) begin
            idx_reg_stage0 <= 4'd0;
            length_reg_stage0 <= 4'd0;
            ready_reg <= 1'b1;
        end else if (start || start_stage1 || start_stage2) begin
            idx_reg_stage0 <= 4'd0;
            length_reg_stage0 <= 4'd0;
            ready_reg <= 1'b1;
        end else if (node_valid) begin
            idx_reg_stage0 <= (idx_reg_stage0 == MAX_LEN-1) ? 4'd0 : idx_reg_stage0 + 1'b1;
            length_reg_stage0 <= (length_reg_stage0 == MAX_LEN) ? MAX_LEN : length_reg_stage0 + 1'b1;
            ready_reg <= 1'b1;
        end
    end

    // Latch idx and length for use in next pipeline stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            idx_reg_stage1 <= 4'd0;
            length_reg_stage1 <= 4'd0;
        end else begin
            idx_reg_stage1 <= idx_reg_stage0;
            length_reg_stage1 <= length_reg_stage0;
        end
    end

    // Pipeline Stage 3: Memory Write
    reg [DW-1:0]       mem_data_stage3;
    reg [3:0]          mem_idx_stage3;
    reg                mem_we_stage3;
    reg                flush_stage3, start_stage3;
    reg                node_valid_stage3;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mem_data_stage3 <= {DW{1'b0}};
            mem_idx_stage3 <= 4'd0;
            mem_we_stage3 <= 1'b0;
            flush_stage3 <= 1'b0;
            start_stage3 <= 1'b0;
            node_valid_stage3 <= 1'b0;
        end else begin
            mem_data_stage3 <= node_data_stage2;
            mem_idx_stage3 <= idx_stage2;
            mem_we_stage3 <= node_valid_stage2;
            flush_stage3 <= flush_stage2;
            start_stage3 <= start_stage2;
            node_valid_stage3 <= node_valid_stage2;
        end
    end

    // Memory: true dual-port, pipelined write
    reg [DW-1:0]       mem_array_stage3 [0:MAX_LEN-1];
    reg [DW-1:0]       mem_array_stage4 [0:MAX_LEN-1];
    integer            i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for(i=0; i<MAX_LEN; i=i+1)
                mem_array_stage3[i] <= {DW{1'b0}};
        end else if (flush_stage3 || start_stage3) begin
            for(i=0; i<MAX_LEN; i=i+1)
                mem_array_stage3[i] <= {DW{1'b0}};
        end else if (mem_we_stage3) begin
            mem_array_stage3[mem_idx_stage3] <= mem_data_stage3;
        end
    end

    // Pipeline Stage 4: Memory Readout Buffer
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for(i=0; i<MAX_LEN; i=i+1)
                mem_array_stage4[i] <= {DW{1'b0}};
        end else begin
            for(i=0; i<MAX_LEN; i=i+1)
                mem_array_stage4[i] <= mem_array_stage3[i];
        end
    end

    // Pipeline Stage 5: Output Buffer
    reg [DW-1:0]       mem_array_stage5 [0:MAX_LEN-1];
    reg                valid_stage5;
    reg [3:0]          length_stage5;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for(i=0; i<MAX_LEN; i=i+1)
                mem_array_stage5[i] <= {DW{1'b0}};
            valid_stage5 <= 1'b0;
            length_stage5 <= 4'd0;
        end else begin
            for(i=0; i<MAX_LEN; i=i+1)
                mem_array_stage5[i] <= mem_array_stage4[i];
            valid_stage5 <= node_valid_stage3;
            length_stage5 <= length_stage2;
        end
    end

    // Output assignment
    genvar g;
    generate
        for (g=0; g<MAX_LEN; g=g+1) begin : array_output_assign
            assign array_out[g*DW +: DW] = mem_array_stage5[g];
        end
    endgenerate

    assign length = length_stage5;
    assign valid  = valid_stage5;
    assign ready  = ready_reg;

endmodule