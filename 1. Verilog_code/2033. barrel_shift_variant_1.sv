//SystemVerilog
// Top-level pipelined barrel shifter module with optimized always block structure
module barrel_shift #(parameter SHIFT=3, WIDTH=8) (
    input  wire                clk,
    input  wire                rst_n,
    input  wire [WIDTH-1:0]    data_in,
    output wire [WIDTH-1:0]    data_out
);

    //===========================================================================
    // Stage 1: Input Register Logic
    // Latches input data into stage 1 register
    //===========================================================================
    reg [WIDTH-1:0] data_in_stage1;
    always @(posedge clk or negedge rst_n) begin : input_register_proc
        if (!rst_n)
            data_in_stage1 <= {WIDTH{1'b0}};
        else
            data_in_stage1 <= data_in;
    end

    //===========================================================================
    // Stage 2: Data Concatenation Logic
    // Concatenates stage 1 data for barrel shifting
    //===========================================================================
    wire [2*WIDTH-1:0] concatenated_data_stage2;
    assign concatenated_data_stage2 = {data_in_stage1, data_in_stage1};

    //===========================================================================
    // Stage 2: Shifted Data Register Logic
    // Performs shift and registers the result
    //===========================================================================
    reg [2*WIDTH-1:0] shifted_data_stage2;
    always @(posedge clk or negedge rst_n) begin : shift_register_proc
        if (!rst_n)
            shifted_data_stage2 <= {(2*WIDTH){1'b0}};
        else
            shifted_data_stage2 <= concatenated_data_stage2 >> (WIDTH - SHIFT);
    end

    //===========================================================================
    // Stage 3: Output Register Logic
    // Captures the shifted data into output stage register
    //===========================================================================
    reg [WIDTH-1:0] data_out_stage3;
    always @(posedge clk or negedge rst_n) begin : output_register_proc
        if (!rst_n)
            data_out_stage3 <= {WIDTH{1'b0}};
        else
            data_out_stage3 <= shifted_data_stage2[WIDTH-1:0];
    end

    //===========================================================================
    // Output Assignment Logic
    //===========================================================================
    assign data_out = data_out_stage3;

endmodule