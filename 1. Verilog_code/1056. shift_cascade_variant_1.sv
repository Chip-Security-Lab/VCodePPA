//SystemVerilog
module shift_cascade #(parameter WIDTH=8, DEPTH=4) (
    input clk,
    input en,
    input [WIDTH-1:0] data_in,
    output [WIDTH-1:0] data_out
);
    reg [WIDTH-1:0] shift_stage1;
    reg [WIDTH-1:0] shift_stage2;
    reg [WIDTH-1:0] shift_stage3;
    reg [WIDTH-1:0] shift_stage4;

    // Moved pipeline registers after combination logic (forward retiming)
    reg [WIDTH-1:0] subtractor_in_a;
    reg [WIDTH-1:0] subtractor_in_b;
    reg [WIDTH-1:0] subtractor_result_pipe;

    wire [WIDTH-1:0] subtractor_a_wire;
    wire [WIDTH-1:0] subtractor_b_wire;
    wire [WIDTH-1:0] subtractor_result_wire;

    // Shift register chain
    always @(posedge clk) begin
        if (en) begin
            shift_stage1 <= data_in;
            if (DEPTH > 1) shift_stage2 <= shift_stage1;
            if (DEPTH > 2) shift_stage3 <= shift_stage2;
            if (DEPTH > 3) shift_stage4 <= shift_stage3;
        end
    end

    // Assign for subtractor input (combinational path)
    assign subtractor_a_wire = shift_stage3;
    assign subtractor_b_wire = shift_stage4;

    // Pipeline registers for subtractor input, after combinational logic
    always @(posedge clk) begin
        if (en && DEPTH > 3) begin
            subtractor_in_a <= subtractor_a_wire;
            subtractor_in_b <= subtractor_b_wire;
        end
    end

    // Parallel prefix subtractor instance
    parallel_prefix_subtractor_8bit u_parallel_prefix_subtractor_8bit (
        .clk(clk),
        .en(en),
        .minuend(subtractor_in_a),
        .subtrahend(subtractor_in_b),
        .difference(subtractor_result_wire)
    );

    // Pipeline register for subtractor output
    always @(posedge clk) begin
        if (en && DEPTH > 3) begin
            subtractor_result_pipe <= subtractor_result_wire;
        end
    end

    assign data_out = (DEPTH == 1) ? shift_stage1 :
                      (DEPTH == 2) ? shift_stage2 :
                      (DEPTH == 3) ? shift_stage3 :
                      subtractor_result_pipe;

endmodule

module parallel_prefix_subtractor_8bit (
    input clk,
    input en,
    input  [7:0] minuend,
    input  [7:0] subtrahend,
    output reg [7:0] difference
);
    reg [7:0] g_stage1, p_stage1;
    reg [7:0] g_stage2, p_stage2;
    reg [7:0] g_stage3, p_stage3;
    reg [7:0] borrow_stage;
    reg [7:0] minuend_reg, subtrahend_reg;

    // Inputs registered after combinational logic (forward retiming)
    always @(posedge clk) begin
        if (en) begin
            minuend_reg <= minuend;
            subtrahend_reg <= subtrahend;
        end
    end

    // Stage 1: Generate and propagate
    integer idx;
    always @(posedge clk) begin
        if (en) begin
            for (idx = 0; idx < 8; idx = idx + 1) begin
                g_stage1[idx] <= ~minuend_reg[idx] & subtrahend_reg[idx];
                p_stage1[idx] <= ~(minuend_reg[idx] ^ subtrahend_reg[idx]);
            end
        end
    end

    // Stage 2: First prefix level
    always @(posedge clk) begin
        if (en) begin
            g_stage2[0] <= g_stage1[0];
            p_stage2[0] <= p_stage1[0];
            for (idx = 1; idx < 8; idx = idx + 1) begin
                g_stage2[idx] <= g_stage1[idx] | (p_stage1[idx] & g_stage1[idx-1]);
                p_stage2[idx] <= p_stage1[idx] & p_stage1[idx-1];
            end
        end
    end

    // Stage 3: Second prefix level
    always @(posedge clk) begin
        if (en) begin
            g_stage3[1:0] <= g_stage2[1:0];
            p_stage3[1:0] <= p_stage2[1:0];
            for (idx = 2; idx < 8; idx = idx + 1) begin
                g_stage3[idx] <= g_stage2[idx] | (p_stage2[idx] & g_stage2[idx-2]);
                p_stage3[idx] <= p_stage2[idx] & p_stage2[idx-2];
            end
        end
    end

    // Stage 4: Borrow chain
    always @(posedge clk) begin
        if (en) begin
            borrow_stage[0] <= 1'b0;
            borrow_stage[1] <= g_stage2[0];
            borrow_stage[2] <= g_stage3[1];
            borrow_stage[3] <= g_stage3[2];
            borrow_stage[4] <= g_stage3[3];
            borrow_stage[5] <= g_stage3[4];
            borrow_stage[6] <= g_stage3[5];
            borrow_stage[7] <= g_stage3[6];
        end
    end

    // Stage 5: Difference calculation
    always @(posedge clk) begin
        if (en) begin
            difference <= minuend_reg ^ subtrahend_reg ^ borrow_stage;
        end
    end

endmodule