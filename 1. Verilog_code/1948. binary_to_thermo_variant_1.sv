//SystemVerilog
module binary_to_thermo #(
    parameter BIN_WIDTH = 3
)(
    input  wire [BIN_WIDTH-1:0] bin_in,
    output wire [(1<<BIN_WIDTH)-1:0] thermo_out
);

    // Stage 1: Decode input and form intermediate signals
    wire [BIN_WIDTH-1:0] bin_stage1;
    reg  [(1<<BIN_WIDTH)-1:0] one_hot_stage1;
    reg  [(1<<BIN_WIDTH)-1:0] one_hot_stage2;

    // Register stage to break long path and pipeline the input
    reg  [BIN_WIDTH-1:0] bin_reg_stage1;
    always @(*) begin
        bin_reg_stage1 = bin_in;
    end

    assign bin_stage1 = bin_reg_stage1;

    // Stage 2: Generate one-hot thermometer code
    always @(*) begin
        if (bin_stage1 == 0)
            one_hot_stage1 = {((1<<BIN_WIDTH)){1'b0}};
        else if (bin_stage1 == (1<<BIN_WIDTH))
            one_hot_stage1 = {((1<<BIN_WIDTH)){1'b1}};
        else
            one_hot_stage1 = ({((1<<BIN_WIDTH)){1'b1}} >> ((1<<BIN_WIDTH) - bin_stage1));
    end

    // Pipeline register to break combinational depth
    always @(*) begin
        one_hot_stage2 = one_hot_stage1;
    end

    // Final output assignment
    assign thermo_out = one_hot_stage2;

endmodule