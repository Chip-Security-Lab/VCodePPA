//SystemVerilog
module conditional_shift_register_pipeline #(parameter WIDTH=8) (
    input               clk,
    input               reset,
    input  [WIDTH-1:0]  parallel_in,
    input               shift_in_bit,
    input  [1:0]        mode, // 00=hold, 01=load, 10=shift right, 11=shift left
    input               condition,  // Only perform operation if condition is true
    output [WIDTH-1:0]  parallel_out,
    output              shift_out_bit
);

    // Stage 1: Input Latching and Mode Decode
    reg [WIDTH-1:0]  latched_parallel_in;
    reg              latched_shift_in_bit;
    reg [1:0]        latched_mode;
    reg              latched_condition;
    reg              latched_valid;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            latched_parallel_in   <= {WIDTH{1'b0}};
            latched_shift_in_bit  <= 1'b0;
            latched_mode          <= 2'b00;
            latched_condition     <= 1'b0;
            latched_valid         <= 1'b0;
        end else begin
            latched_parallel_in   <= parallel_in;
            latched_shift_in_bit  <= shift_in_bit;
            latched_mode          <= mode;
            latched_condition     <= condition;
            latched_valid         <= 1'b1;
        end
    end

    // Stage 2: Register Current Data & Prepare Shift
    reg [WIDTH-1:0]  reg_parallel_out;
    reg [WIDTH-1:0]  reg_parallel_in;
    reg              reg_shift_in_bit;
    reg [1:0]        reg_mode;
    reg              reg_condition;
    reg              reg_valid;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            reg_parallel_out  <= {WIDTH{1'b0}};
            reg_parallel_in   <= {WIDTH{1'b0}};
            reg_shift_in_bit  <= 1'b0;
            reg_mode          <= 2'b00;
            reg_condition     <= 1'b0;
            reg_valid         <= 1'b0;
        end else begin
            reg_parallel_out  <= next_parallel_out;
            reg_parallel_in   <= latched_parallel_in;
            reg_shift_in_bit  <= latched_shift_in_bit;
            reg_mode          <= latched_mode;
            reg_condition     <= latched_condition;
            reg_valid         <= latched_valid;
        end
    end

    // Stage 3: Core Operation (Hold/Load/Shift Right/Shift Left)
    reg [WIDTH-1:0]  next_parallel_out;
    reg              next_valid;
    reg [1:0]        next_mode;
    reg              next_condition;
    reg              next_shift_in_bit;
    reg [WIDTH-1:0]  next_parallel_in;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            next_parallel_out  <= {WIDTH{1'b0}};
            next_valid         <= 1'b0;
            next_mode          <= 2'b00;
            next_condition     <= 1'b0;
            next_shift_in_bit  <= 1'b0;
            next_parallel_in   <= {WIDTH{1'b0}};
        end else begin
            next_parallel_in   <= reg_parallel_in;
            next_shift_in_bit  <= reg_shift_in_bit;
            next_mode          <= reg_mode;
            next_condition     <= reg_condition;
            next_valid         <= reg_valid;

            // Optimized comparison logic using casez and direct range check
            if (reg_condition) begin
                casez (reg_mode)
                    2'b01: next_parallel_out <= reg_parallel_in;
                    2'b10: next_parallel_out <= {reg_shift_in_bit, reg_parallel_out[WIDTH-1:1]};
                    2'b11: next_parallel_out <= {reg_parallel_out[WIDTH-2:0], reg_shift_in_bit};
                    default: next_parallel_out <= reg_parallel_out;
                endcase
            end else begin
                next_parallel_out <= reg_parallel_out;
            end
        end
    end

    // Output Register Stage (timing closure)
    reg [WIDTH-1:0]  output_parallel_out;
    reg              output_valid;
    reg [1:0]        output_mode;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            output_parallel_out <= {WIDTH{1'b0}};
            output_valid        <= 1'b0;
            output_mode         <= 2'b00;
        end else begin
            output_parallel_out <= next_parallel_out;
            output_valid        <= next_valid;
            output_mode         <= next_mode;
        end
    end

    // Output assignments with optimized comparison
    assign parallel_out = output_parallel_out;
    assign shift_out_bit = output_mode[1] & ~output_mode[0] ? output_parallel_out[0] : output_parallel_out[WIDTH-1];

endmodule