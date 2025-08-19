//SystemVerilog
module demux_async_reset_pipeline (
    input  wire        clk,                  // Clock signal
    input  wire        rst_n,                // Active-low async reset
    input  wire        data,                 // Input data
    input  wire [2:0]  channel,              // Channel selection
    input  wire        in_valid,             // Input valid signal
    output wire        in_ready,             // Input ready (always ready in this design)
    output reg  [7:0]  out_channels,         // Output channels
    output reg         out_valid,            // Output valid signal
    input  wire        out_ready,            // Output ready (for future extension)
    input  wire        flush                 // Flush pipeline
);

    // Stage 1 registers: capture inputs
    reg        data_reg_stage1;
    reg [2:0]  channel_reg_stage1;
    reg        valid_reg_stage1;

    // Stage 2 registers: output calculation
    reg        data_reg_stage2;
    reg [2:0]  channel_reg_stage2;
    reg        valid_reg_stage2;

    // Input always ready in this simple pipeline
    assign in_ready = 1'b1;

    // Stage 1: Register input signals
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg_stage1    <= 1'b0;
            channel_reg_stage1 <= 3'b000;
            valid_reg_stage1   <= 1'b0;
        end else if (flush) begin
            data_reg_stage1    <= 1'b0;
            channel_reg_stage1 <= 3'b000;
            valid_reg_stage1   <= 1'b0;
        end else if (in_valid) begin
            data_reg_stage1    <= data;
            channel_reg_stage1 <= channel;
            valid_reg_stage1   <= 1'b1;
        end else begin
            valid_reg_stage1   <= 1'b0;
        end
    end

    // Stage 2: Register intermediate signals
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg_stage2    <= 1'b0;
            channel_reg_stage2 <= 3'b000;
            valid_reg_stage2   <= 1'b0;
        end else if (flush) begin
            data_reg_stage2    <= 1'b0;
            channel_reg_stage2 <= 3'b000;
            valid_reg_stage2   <= 1'b0;
        end else if (valid_reg_stage1) begin
            data_reg_stage2    <= data_reg_stage1;
            channel_reg_stage2 <= channel_reg_stage1;
            valid_reg_stage2   <= 1'b1;
        end else begin
            valid_reg_stage2   <= 1'b0;
        end
    end

    // Optimized Stage 3: Output logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_channels <= 8'b0;
            out_valid    <= 1'b0;
        end else if (flush) begin
            out_channels <= 8'b0;
            out_valid    <= 1'b0;
        end else if (valid_reg_stage2) begin
            out_channels <= (8'b1 << channel_reg_stage2) & {8{data_reg_stage2}};
            out_valid    <= 1'b1;
        end else begin
            out_channels <= 8'b0;
            out_valid    <= 1'b0;
        end
    end

endmodule