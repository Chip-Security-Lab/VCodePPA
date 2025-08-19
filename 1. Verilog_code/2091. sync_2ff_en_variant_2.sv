//SystemVerilog
// Top-level module: Two-stage synchronizer with enable and parameterizable data width (timing-optimized)
module sync_2ff_en #(parameter DW=8) (
    input                  src_clk,
    input                  dst_clk,
    input                  rst_n,
    input                  en,
    input      [DW-1:0]    async_in,
    output reg [DW-1:0]    synced_out
);

    wire [DW-1:0] sync_stage_data;

    // First stage: Capture asynchronous input data
    sync_stage #(
        .DW(DW)
    ) u_sync_stage (
        .clk      (dst_clk),
        .rst_n    (rst_n),
        .en       (en),
        .din      (async_in),
        .dout     (sync_stage_data)
    );

    // Second stage: Output registered synchronized data
    sync_output_stage #(
        .DW(DW)
    ) u_sync_output_stage (
        .clk      (dst_clk),
        .rst_n    (rst_n),
        .en       (en),
        .din      (sync_stage_data),
        .dout     (synced_out)
    );

endmodule

// ---------------------------------------------------------------------------
// Submodule: First stage of synchronizer (timing-optimized enable logic)
// ---------------------------------------------------------------------------
module sync_stage #(parameter DW=8) (
    input               clk,
    input               rst_n,
    input               en,
    input  [DW-1:0]     din,
    output reg [DW-1:0] dout
);

    reg [DW-1:0] latch_in;
    reg          rst_n_int;
    wire         en_active;

    assign en_active = en & rst_n;  // Path balancing: combine enable and reset

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            latch_in <= {DW{1'b0}};
            rst_n_int <= 1'b0;
        end else begin
            latch_in <= din;
            rst_n_int <= 1'b1;
        end
    end

    always @(posedge clk) begin
        if (!rst_n_int)
            dout <= {DW{1'b0}};
        else if (en)
            dout <= latch_in;
        // else retain value
    end

endmodule

// ---------------------------------------------------------------------------
// Submodule: Second stage of synchronizer (timing-optimized enable logic)
// ---------------------------------------------------------------------------
module sync_output_stage #(parameter DW=8) (
    input               clk,
    input               rst_n,
    input               en,
    input  [DW-1:0]     din,
    output reg [DW-1:0] dout
);

    reg [DW-1:0] din_buf;
    reg          rst_n_flag;
    wire         en_valid;

    assign en_valid = en & rst_n; // Balanced path for enable and reset

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            din_buf <= {DW{1'b0}};
            rst_n_flag <= 1'b0;
        end else begin
            din_buf <= din;
            rst_n_flag <= 1'b1;
        end
    end

    always @(posedge clk) begin
        if (!rst_n_flag)
            dout <= {DW{1'b0}};
        else if (en)
            dout <= din_buf;
        // else retain value
    end

endmodule