//SystemVerilog
module rotate_right_en_pipeline #(parameter W=8) (
    input                  clk,
    input                  en,
    input                  rst_n,
    input      [W-1:0]     din,
    output reg [W-1:0]     dout
);

    // Stage 1: Latch input and control
    reg         en_stage1;
    reg [W-1:0] din_stage1;
    reg         valid_stage1;

    // Stage 2: Rotate and output
    reg [W-1:0] rotated_stage2;
    reg         en_stage2;
    reg         valid_stage2;

    // Pipeline flush logic
    wire        flush;
    assign flush = !rst_n;

    // Stage 1: Register inputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            din_stage1    <= {W{1'b0}};
            en_stage1     <= 1'b0;
            valid_stage1  <= 1'b0;
        end else begin
            din_stage1    <= din;
            en_stage1     <= en;
            valid_stage1  <= 1'b1;
        end
    end

    // Stage 2: Rotate operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rotated_stage2 <= {W{1'b0}};
            en_stage2      <= 1'b0;
            valid_stage2   <= 1'b0;
        end else begin
            rotated_stage2 <= {din_stage1[0], din_stage1[W-1:1]};
            en_stage2      <= en_stage1;
            valid_stage2   <= valid_stage1;
        end
    end

    // Output logic with pipeline enable and flush handling
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dout <= {W{1'b0}};
        end else if (valid_stage2) begin
            if (en_stage2)
                dout <= rotated_stage2;
            else
                dout <= dout;
        end
    end

endmodule