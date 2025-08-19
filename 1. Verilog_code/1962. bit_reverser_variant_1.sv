//SystemVerilog
module bit_reverser #(
    parameter WIDTH = 8
)(
    input                  clk,
    input                  rst_n,
    input  [WIDTH-1:0]     data_in,
    input                  data_in_valid,
    output reg [WIDTH-1:0] data_out,
    output reg             data_out_valid
);

    // Stage 1: Input latching registers
    reg [WIDTH-1:0] input_latched_data;
    reg             input_latched_valid;

    // Stage 2: Bit reversal registers
    reg [WIDTH-1:0] reversed_data;
    reg             reversed_valid;

    // Internal wire for reversed bits (combinational)
    reg [WIDTH-1:0] reversed_data_next;
    integer         bit_idx;

    //===========================================================
    // Stage 1: Input Latching
    //===========================================================
    // Latch input data and valid signal on each clock cycle
    always @(posedge clk or negedge rst_n) begin : input_latching_proc
        if (!rst_n) begin
            input_latched_data  <= {WIDTH{1'b0}};
            input_latched_valid <= 1'b0;
        end else begin
            input_latched_data  <= data_in;
            input_latched_valid <= data_in_valid;
        end
    end

    //===========================================================
    // Stage 2: Bit Reversal (Combinational)
    //===========================================================
    // Generate reversed bits combinationally for next clock
    always @(*) begin : bit_reversal_comb_proc
        for (bit_idx = 0; bit_idx < WIDTH; bit_idx = bit_idx + 1) begin
            reversed_data_next[bit_idx] = input_latched_data[WIDTH-1-bit_idx];
        end
    end

    //===========================================================
    // Stage 2: Bit Reversal Registering
    //===========================================================
    // Register reversed data and valid signal
    always @(posedge clk or negedge rst_n) begin : bit_reversal_reg_proc
        if (!rst_n) begin
            reversed_data  <= {WIDTH{1'b0}};
            reversed_valid <= 1'b0;
        end else begin
            reversed_data  <= reversed_data_next;
            reversed_valid <= input_latched_valid;
        end
    end

    //===========================================================
    // Stage 3: Output Register
    //===========================================================
    // Register output data and valid signal
    always @(posedge clk or negedge rst_n) begin : output_reg_proc
        if (!rst_n) begin
            data_out       <= {WIDTH{1'b0}};
            data_out_valid <= 1'b0;
        end else begin
            data_out       <= reversed_data;
            data_out_valid <= reversed_valid;
        end
    end

endmodule