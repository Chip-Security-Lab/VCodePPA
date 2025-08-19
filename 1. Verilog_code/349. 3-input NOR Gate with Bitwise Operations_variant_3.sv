//SystemVerilog
module nor3_bitwise (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [2:0]  A_in,    // 输入数据
    output wire        Y_out    // 输出结果
);

    //==================================================================
    // Pipeline Stage 1: Input Register
    //==================================================================
    reg [2:0] A_pipe_stage1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            A_pipe_stage1 <= 3'b0;
        else
            A_pipe_stage1 <= A_in;
    end

    //==================================================================
    // Pipeline Stage 2: OR Reduction Register
    //==================================================================
    reg or_pipe_stage2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            or_pipe_stage2 <= 1'b0;
        else
            or_pipe_stage2 <= |A_pipe_stage1;
    end

    //==================================================================
    // Pipeline Stage 3: NOR Output Register
    //==================================================================
    reg Y_pipe_stage3;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            Y_pipe_stage3 <= 1'b0;
        else
            Y_pipe_stage3 <= ~or_pipe_stage2;
    end

    //==================================================================
    // Output Assignment
    //==================================================================
    assign Y_out = Y_pipe_stage3;

endmodule