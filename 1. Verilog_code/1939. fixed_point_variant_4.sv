//SystemVerilog
// Top-level module: Structured pipelined fixed-point right shifter
module fixed_point #(
    parameter Q = 4,          // Fractional bits
    parameter DW = 8          // Data width
)(
    input  wire                  clk,          // System clock
    input  wire                  rst_n,        // Active-low synchronous reset
    input  wire signed [DW-1:0]  in_data,      // Input data
    output wire signed [DW-1:0]  out_data      // Output data
);

    //--------------------------------------------------------------------------
    // Pipeline Stage 1: Input Register
    // Registers the input data for clear dataflow
    //--------------------------------------------------------------------------
    reg signed [DW-1:0] stage1_data;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            stage1_data <= {DW{1'b0}};
        else
            stage1_data <= in_data;
    end

    //--------------------------------------------------------------------------
    // Pipeline Stage 2: Arithmetic Right Shifter
    // Shifts the registered input and provides pipelined output
    //--------------------------------------------------------------------------
    reg signed [DW-1:0] stage2_shifted_data;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            stage2_shifted_data <= {DW{1'b0}};
        else
            stage2_shifted_data <= stage1_data >>> Q;
    end

    //--------------------------------------------------------------------------
    // Pipeline Stage 3: Output Register
    // Final output register for improved timing and structured dataflow
    //--------------------------------------------------------------------------
    reg signed [DW-1:0] stage3_out_data;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            stage3_out_data <= {DW{1'b0}};
        else
            stage3_out_data <= stage2_shifted_data;
    end

    //--------------------------------------------------------------------------
    // Output assignment
    //--------------------------------------------------------------------------
    assign out_data = stage3_out_data;

endmodule