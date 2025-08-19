//SystemVerilog
module BitSliceMux #(
    parameter N = 4,
    parameter DW = 4
) (
    input  wire              clk,
    input  wire              rst_n,
    input  wire              in_valid,
    input  wire [N-1:0]      sel,
    input  wire [(DW*N)-1:0] din,
    output wire              out_valid,
    output wire [DW-1:0]     dout
);

    // Pipeline valid signals
    reg  valid_stage1;
    reg  valid_stage2;
    reg  valid_stage3;

    // Pipeline stage 1: Decode and gate input bits with select signals
    reg  [N-1:0] mux_bits_stage1 [DW-1:0];
    integer i, j;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < DW; i = i + 1)
                for (j = 0; j < N; j = j + 1)
                    mux_bits_stage1[i][j] <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            for (i = 0; i < DW; i = i + 1) begin
                for (j = 0; j < N; j = j + 1) begin
                    mux_bits_stage1[i][j] <= din[(j*DW) + i] & sel[j];
                end
            end
            valid_stage1 <= in_valid;
        end
    end

    // Pipeline stage 2: OR reduction
    reg [DW-1:0] mux_or_stage2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mux_or_stage2 <= {DW{1'b0}};
            valid_stage2  <= 1'b0;
        end else begin
            for (i = 0; i < DW; i = i + 1) begin
                mux_or_stage2[i] <= |mux_bits_stage1[i];
            end
            valid_stage2 <= valid_stage1;
        end
    end

    // Pipeline stage 3: Register output
    reg [DW-1:0] dout_stage3;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dout_stage3   <= {DW{1'b0}};
            valid_stage3  <= 1'b0;
        end else begin
            dout_stage3  <= mux_or_stage2;
            valid_stage3 <= valid_stage2;
        end
    end

    assign dout      = dout_stage3;
    assign out_valid = valid_stage3;

endmodule