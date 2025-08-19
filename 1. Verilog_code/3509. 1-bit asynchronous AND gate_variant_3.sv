//SystemVerilog (IEEE 1364-2005)
// Top-level pipelined AND gate module with improved hierarchical structure
module and_gate_1_pipelined (
    input  wire        clk,          // System clock
    input  wire        rst_n,        // Active low reset
    input  wire        data_a_in,    // Input A data stream
    input  wire        data_b_in,    // Input B data stream
    input  wire        data_valid,   // Input data valid signal
    output wire        result_valid, // Output result valid signal
    output wire        result        // Pipelined AND result
);

    // Internal signals for connecting sub-modules
    wire [1:0] registered_data;
    wire stage1_valid;
    
    // Input stage module instantiation
    input_stage u_input_stage (
        .clk          (clk),
        .rst_n        (rst_n),
        .data_a_in    (data_a_in),
        .data_b_in    (data_b_in),
        .data_valid   (data_valid),
        .data_out     (registered_data),
        .valid_out    (stage1_valid)
    );
    
    // Computation stage module instantiation
    computation_stage u_computation_stage (
        .clk          (clk),
        .rst_n        (rst_n),
        .data_in      (registered_data),
        .valid_in     (stage1_valid),
        .result       (result),
        .result_valid (result_valid)
    );

endmodule

// Input registration stage module
module input_stage (
    input  wire        clk,        // System clock
    input  wire        rst_n,      // Active low reset
    input  wire        data_a_in,  // Input A data stream
    input  wire        data_b_in,  // Input B data stream
    input  wire        data_valid, // Input data valid signal
    output reg  [1:0]  data_out,   // Registered input data [data_a, data_b]
    output reg         valid_out   // Registered valid signal
);

    // Register input data and valid signal
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out  <= 2'b00;
            valid_out <= 1'b0;
        end else begin
            data_out[0] <= data_a_in;
            data_out[1] <= data_b_in;
            valid_out   <= data_valid;
        end
    end

endmodule

// Computation stage module
module computation_stage (
    input  wire        clk,          // System clock
    input  wire        rst_n,        // Active low reset
    input  wire [1:0]  data_in,      // Input data [data_a, data_b]
    input  wire        valid_in,     // Input valid signal
    output reg         result,       // Computation result
    output reg         result_valid  // Result valid signal
);

    // Perform AND operation and register results
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result       <= 1'b0;
            result_valid <= 1'b0;
        end else begin
            // Compute AND of two inputs and register the result
            result       <= data_in[0] & data_in[1];
            result_valid <= valid_in;
        end
    end

endmodule