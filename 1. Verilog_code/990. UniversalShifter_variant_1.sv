//SystemVerilog
module UniversalShifter #(parameter WIDTH=8) (
    input wire clk,
    input wire [1:0] mode, // 00:hold 01:left 10:right 11:load
    input wire serial_in,
    input wire [WIDTH-1:0] parallel_in,
    output reg [WIDTH-1:0] data_reg
);

// Top-Level Pipelined Data Path
generate
    if (WIDTH == 2) begin : gen_structured_shifter_2bit

        // Stage 1: Precompute all possible next states
        wire [1:0] left_shift_stage1;
        wire [1:0] right_shift_stage1;
        wire [1:0] load_stage1;
        wire [1:0] hold_stage1;

        assign left_shift_stage1  = {data_reg[0], serial_in};   // Left shift
        assign right_shift_stage1 = {serial_in, data_reg[1]};   // Right shift
        assign load_stage1        = parallel_in;                // Parallel load
        assign hold_stage1        = data_reg;                   // Hold

        // Stage 2: Select next state based on mode (with pipelined register)
        reg [1:0] left_shift_stage2;
        reg [1:0] right_shift_stage2;
        reg [1:0] load_stage2;
        reg [1:0] hold_stage2;

        always @(posedge clk) begin
            left_shift_stage2  <= left_shift_stage1;
            right_shift_stage2 <= right_shift_stage1;
            load_stage2        <= load_stage1;
            hold_stage2        <= hold_stage1;
        end

        // Stage 3: Registered output update with clear selection logic
        always @(posedge clk) begin
            case (mode)
                2'b01: data_reg <= left_shift_stage2;      // Shift left
                2'b10: data_reg <= right_shift_stage2;     // Shift right
                2'b11: data_reg <= load_stage2;            // Load
                default: data_reg <= hold_stage2;          // Hold
            endcase
        end

    end else begin : gen_structured_shifter_generic

        // Stage 1: Precompute all possible next states for generic WIDTH
        wire [WIDTH-1:0] left_shift_stage1;
        wire [WIDTH-1:0] right_shift_stage1;
        wire [WIDTH-1:0] load_stage1;
        wire [WIDTH-1:0] hold_stage1;

        assign left_shift_stage1  = {data_reg[WIDTH-2:0], serial_in};    // Left shift
        assign right_shift_stage1 = {serial_in, data_reg[WIDTH-1:1]};    // Right shift
        assign load_stage1        = parallel_in;                         // Parallel load
        assign hold_stage1        = data_reg;                            // Hold

        // Stage 2: Pipeline register stage to break long path
        reg [WIDTH-1:0] left_shift_stage2;
        reg [WIDTH-1:0] right_shift_stage2;
        reg [WIDTH-1:0] load_stage2;
        reg [WIDTH-1:0] hold_stage2;

        always @(posedge clk) begin
            left_shift_stage2  <= left_shift_stage1;
            right_shift_stage2 <= right_shift_stage1;
            load_stage2        <= load_stage1;
            hold_stage2        <= hold_stage1;
        end

        // Stage 3: Registered output update with clear selection logic
        always @(posedge clk) begin
            case (mode)
                2'b01: data_reg <= left_shift_stage2;      // Shift left
                2'b10: data_reg <= right_shift_stage2;     // Shift right
                2'b11: data_reg <= load_stage2;            // Load
                default: data_reg <= hold_stage2;          // Hold
            endcase
        end

    end
endgenerate

endmodule