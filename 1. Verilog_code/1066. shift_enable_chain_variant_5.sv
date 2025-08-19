//SystemVerilog
module shift_enable_chain_pipeline #(parameter WIDTH=8) (
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  en,
    input  wire  [WIDTH-1:0]     din,
    output reg   [WIDTH-1:0]     dout,
    output reg                   dout_valid
);

    // Stage 1: Latch input on enable
    reg [WIDTH-1:0] buffer_stage1;
    reg             valid_stage1;

    // Stage 2: Pre-shift lower complexity (split original shift)
    reg [WIDTH-1:0] buffer_stage2;
    reg             valid_stage2;

    // Stage 3: Complete shift (finalize)
    reg [WIDTH-1:0] buffer_stage3;
    reg             valid_stage3;

    // Stage 1: Capture input when enabled
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            buffer_stage1 <= {WIDTH{1'b0}};
            valid_stage1  <= 1'b0;
        end else begin
            if (en) begin
                buffer_stage1 <= din;
                valid_stage1  <= 1'b1;
            end else begin
                buffer_stage1 <= buffer_stage1;
                valid_stage1  <= 1'b0;
            end
        end
    end

    // Stage 2: Pass input and prepare for shift (split shift into two stages)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            buffer_stage2 <= {WIDTH{1'b0}};
            valid_stage2  <= 1'b0;
        end else begin
            if (valid_stage1) begin
                // Pass input to next pipeline stage, no logic (for balancing)
                buffer_stage2 <= buffer_stage1;
                valid_stage2  <= 1'b1;
            end else begin
                buffer_stage2 <= buffer_stage2;
                valid_stage2  <= 1'b0;
            end
        end
    end

    // Stage 3: Perform the shift operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            buffer_stage3 <= {WIDTH{1'b0}};
            valid_stage3  <= 1'b0;
        end else begin
            if (valid_stage2) begin
                buffer_stage3 <= {buffer_stage2[WIDTH-2:0], 1'b0};
                valid_stage3  <= 1'b1;
            end else begin
                buffer_stage3 <= buffer_stage3;
                valid_stage3  <= 1'b0;
            end
        end
    end

    // Output stage: Register output and valid
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dout       <= {WIDTH{1'b0}};
            dout_valid <= 1'b0;
        end else begin
            if (valid_stage3) begin
                dout       <= buffer_stage3;
                dout_valid <= 1'b1;
            end else begin
                dout       <= dout;
                dout_valid <= 1'b0;
            end
        end
    end

endmodule