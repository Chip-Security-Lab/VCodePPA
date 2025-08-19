//SystemVerilog
// SystemVerilog
module rng_triple_lfsr_19_axi_stream (
    input             clk,
    input             rst,
    input             axis_tready,
    output reg [7:0]  axis_tdata,
    output reg        axis_tvalid,
    output reg        axis_tlast
);

    // LFSR internal state registers
    reg [7:0] lfsr_a;
    reg [7:0] lfsr_b;
    reg [7:0] lfsr_c;

    // Feedback calculation wires
    wire feedback_a;
    wire feedback_b;
    wire feedback_c;

    // Data ready flag
    reg data_ready;

    assign feedback_a = lfsr_a[7] ^ lfsr_a[3];
    assign feedback_b = lfsr_b[7] ^ lfsr_b[2];
    assign feedback_c = lfsr_c[7] ^ lfsr_c[1];

    //===============================================================
    // 1. LFSR State Initialization and Update
    //    - Handles reset and LFSR shifting based on valid/ready signals
    //===============================================================
    always @(posedge clk) begin
        if (rst) begin
            lfsr_a <= 8'hFE;
            lfsr_b <= 8'hBD;
            lfsr_c <= 8'h73;
        end else if (axis_tvalid && axis_tready) begin
            lfsr_a <= {lfsr_a[6:0], feedback_a};
            lfsr_b <= {lfsr_b[6:0], feedback_b};
            lfsr_c <= {lfsr_c[6:0], feedback_c};
        end
    end

    //===============================================================
    // 2. Data Output Generation
    //    - Updates axis_tdata based on LFSR state and protocol logic
    //===============================================================
    always @(posedge clk) begin
        if (rst) begin
            axis_tdata <= 8'd0;
        end else if ((axis_tvalid && axis_tready) || !axis_tvalid) begin
            axis_tdata <= lfsr_a ^ lfsr_b ^ lfsr_c;
        end
    end

    //===============================================================
    // 3. AXI Stream Valid Signal Control
    //    - Generates axis_tvalid based on protocol and reset
    //===============================================================
    always @(posedge clk) begin
        if (rst) begin
            axis_tvalid <= 1'b0;
        end else if ((axis_tvalid && axis_tready) || !axis_tvalid) begin
            axis_tvalid <= 1'b1;
        end
    end

    //===============================================================
    // 4. AXI Stream Last Signal Control
    //    - axis_tlast is always zero in this design
    //===============================================================
    always @(posedge clk) begin
        if (rst) begin
            axis_tlast <= 1'b0;
        end else begin
            axis_tlast <= 1'b0;
        end
    end

    //===============================================================
    // 5. Data Ready Flag Control (not used in output, kept for completeness)
    //===============================================================
    always @(posedge clk) begin
        if (rst) begin
            data_ready <= 1'b0;
        end else begin
            data_ready <= 1'b0;
        end
    end

endmodule