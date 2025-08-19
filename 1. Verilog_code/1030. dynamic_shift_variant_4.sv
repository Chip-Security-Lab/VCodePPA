//SystemVerilog
// Top-level module: Hierarchical dynamic shift unit (Optimized always block structure)
module dynamic_shift #(
    parameter W = 8
)(
    input              clk,
    input      [3:0]   ctrl, // [1:0]: direction, [3:2]: type
    input      [W-1:0] din,
    output reg [W-1:0] dout
);

    // Internal buffered data between stages
    wire [W-1:0] din_buf2_wire;
    wire [W-1:0] shift_result;

    // Input buffering submodule
    shift_input_buffer #(
        .W(W)
    ) u_shift_input_buffer (
        .clk      (clk),
        .din      (din),
        .din_buf2 (din_buf2_wire)
    );

    // Shift operation submodule
    shift_operator #(
        .W(W)
    ) u_shift_operator (
        .clk         (clk),
        .ctrl        (ctrl),
        .din_shift   (din_buf2_wire),
        .shift_dout  (shift_result)
    );

    // Output register: provides registered output
    // Function: Registering the output data
    always @(posedge clk) begin
        dout <= shift_result;
    end

endmodule

// -----------------------------------------------------------------------------
// 子模块：输入缓冲，缓解高扇出，分散负载
// 功能：2级输入采样缓冲，将输入din同步到din_buf2输出
// -----------------------------------------------------------------------------
module shift_input_buffer #(
    parameter W = 8
)(
    input              clk,
    input      [W-1:0] din,
    output reg [W-1:0] din_buf2
);

    reg [W-1:0] din_buf1;

    // Function: First stage input sampling buffer
    always @(posedge clk) begin
        din_buf1 <= din;
    end

    // Function: Second stage input sampling buffer
    always @(posedge clk) begin
        din_buf2 <= din_buf1;
    end

endmodule

// -----------------------------------------------------------------------------
// 子模块：移位操作功能单元
// 功能：根据ctrl信号执行不同类型的移位，支持逻辑/循环左右移
// -----------------------------------------------------------------------------
module shift_operator #(
    parameter W = 8
)(
    input              clk,
    input      [3:0]   ctrl,         // [1:0]: direction, [3:2]: type
    input      [W-1:0] din_shift,
    output reg [W-1:0] shift_dout
);

    reg [W-1:0] logic_shift_result;
    reg [W-1:0] rotate_shift_result;
    reg         is_logic_shift;
    reg [1:0]   direction_bits;

    // Function: Decode shift type and direction
    always @(*) begin
        is_logic_shift   = (ctrl[3:2] == 2'b00) ? 1'b1 : 1'b0;
        direction_bits   = ctrl[1:0];
    end

    // Function: Compute logic shift result
    always @(*) begin
        case (direction_bits)
            2'b00: logic_shift_result = din_shift << 1; // Logic left shift
            2'b01: logic_shift_result = din_shift >> 1; // Logic right shift
            default: logic_shift_result = {W{1'b0}};
        endcase
    end

    // Function: Compute rotate shift result
    always @(*) begin
        case (direction_bits)
            2'b10: rotate_shift_result = {din_shift[W-2:0], din_shift[W-1]}; // Rotate left
            2'b11: rotate_shift_result = {din_shift[0], din_shift[W-1:1]};   // Rotate right
            default: rotate_shift_result = {W{1'b0}};
        endcase
    end

    // Function: Select shift result and register output
    always @(posedge clk) begin
        case ({ctrl[3:2], ctrl[1:0]})
            4'b0000, 4'b0100, 4'b1000, 4'b1100: shift_dout <= din_shift << 1; // Logic left
            4'b0001, 4'b0101, 4'b1001, 4'b1101: shift_dout <= din_shift >> 1; // Logic right
            4'b0010, 4'b0110, 4'b1010, 4'b1110: shift_dout <= {din_shift[W-2:0], din_shift[W-1]}; // Rotate left
            4'b0011, 4'b0111, 4'b1011, 4'b1111: shift_dout <= {din_shift[0], din_shift[W-1:1]};   // Rotate right
            default: shift_dout <= {W{1'b0}};
        endcase
    end

endmodule