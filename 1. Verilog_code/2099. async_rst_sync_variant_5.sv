//SystemVerilog
module async_rst_sync_pipeline #(parameter CH=2) (
    input  wire                  clk,
    input  wire                  async_rst,
    input  wire [CH-1:0]         ch_in,
    input  wire                  in_valid,
    output wire [CH-1:0]         ch_out,
    output wire                  out_valid
);

    // Stage 1 registers
    reg [CH-1:0] ch_in_stage1;
    reg          valid_stage1;

    // Stage 2 registers
    reg [CH-1:0] ch_in_stage2;
    reg          valid_stage2;

    // Stage 3 registers
    reg [CH-1:0] ch_in_stage3;
    reg          valid_stage3;

    // Stage 1: Capture async input
    always @(posedge clk or posedge async_rst) begin
        if (async_rst) begin
            ch_in_stage1  <= {CH{1'b0}};
            valid_stage1  <= 1'b0;
        end else begin
            ch_in_stage1  <= ch_in;
            valid_stage1  <= in_valid;
        end
    end

    // Stage 2: First synchronizer stage
    always @(posedge clk or posedge async_rst) begin
        if (async_rst) begin
            ch_in_stage2  <= {CH{1'b0}};
            valid_stage2  <= 1'b0;
        end else begin
            ch_in_stage2  <= ch_in_stage1;
            valid_stage2  <= valid_stage1;
        end
    end

    // Stage 3: Second synchronizer stage, provides stable output
    always @(posedge clk or posedge async_rst) begin
        if (async_rst) begin
            ch_in_stage3  <= {CH{1'b0}};
            valid_stage3  <= 1'b0;
        end else begin
            ch_in_stage3  <= ch_in_stage2;
            valid_stage3  <= valid_stage2;
        end
    end

    // Output assignment
    assign ch_out   = ch_in_stage3;
    assign out_valid = valid_stage3;

endmodule