//SystemVerilog
module shift_arith_right #(
    parameter WIDTH = 8
)(
    input  [WIDTH-1:0] data_in,
    input  [2:0] shift_amount,
    output [WIDTH-1:0] data_out
);

    // Pipeline Stage 1: Input to Level 0 shift
    reg [WIDTH-1:0] stage0_data;
    reg             stage0_msb;
    always @* begin
        stage0_data = data_in;
        stage0_msb  = data_in[WIDTH-1];
    end

    // Pipeline Stage 2: Level 0 to Level 1 shift
    reg [WIDTH-1:0] stage1_data;
    reg             stage1_msb;
    always @* begin
        if (shift_amount[0])
            stage1_data = {stage0_msb, stage0_data[WIDTH-1:1]};
        else
            stage1_data = stage0_data;
        stage1_msb = stage1_data[WIDTH-1];
    end

    // Pipeline Stage 3: Level 1 to Level 2 shift
    reg [WIDTH-1:0] stage2_data;
    reg             stage2_msb;
    always @* begin
        if (shift_amount[1])
            stage2_data = {{2{stage1_msb}}, stage1_data[WIDTH-1:2]};
        else
            stage2_data = stage1_data;
        stage2_msb = stage2_data[WIDTH-1];
    end

    // Pipeline Stage 4: Level 2 to Output shift
    reg [WIDTH-1:0] stage3_data;
    always @* begin
        if (shift_amount[2])
            stage3_data = {{4{stage2_msb}}, stage2_data[WIDTH-1:4]};
        else
            stage3_data = stage2_data;
    end

    assign data_out = stage3_data;

endmodule