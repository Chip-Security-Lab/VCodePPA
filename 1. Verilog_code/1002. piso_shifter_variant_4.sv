//SystemVerilog
module piso_shifter_pipeline(
    input              clk,
    input              rst,
    input              load,
    input      [7:0]   parallel_in,
    output             serial_out,
    output             valid_out
);

    // Internal registers for pipeline stages (after retiming)
    reg [7:0] parallel_data_reg;
    reg       load_reg;
    reg       valid_reg;

    reg [7:0] shift_reg;
    reg       valid_shift_reg;

    // Stage 1: Register the parallel input and load
    always @(posedge clk) begin
        if (rst) begin
            parallel_data_reg <= 8'b0;
            load_reg          <= 1'b0;
            valid_reg         <= 1'b0;
        end else begin
            parallel_data_reg <= parallel_in;
            load_reg          <= load;
            valid_reg         <= load;
        end
    end

    // Stage 2: Shift operation with registered input, valid propagates with shift
    always @(posedge clk) begin
        if (rst) begin
            shift_reg       <= 8'b0;
            valid_shift_reg <= 1'b0;
        end else begin
            if (load_reg) begin
                shift_reg       <= parallel_data_reg;
                valid_shift_reg <= valid_reg;
            end else begin
                shift_reg       <= {shift_reg[6:0], 1'b0};
                valid_shift_reg <= valid_shift_reg;
            end
        end
    end

    // Stage 3: Output logic (direct assignment, no output register)
    assign serial_out = shift_reg[7];
    assign valid_out  = valid_shift_reg;

endmodule