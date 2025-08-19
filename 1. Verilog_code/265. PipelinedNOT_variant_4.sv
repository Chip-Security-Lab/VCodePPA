//SystemVerilog
// Top-level pipelined NOT module with enhanced architecture
module PipelinedNOT #(
    parameter DATA_WIDTH = 32
)(
    input                   clk,
    input                   rst_n,       // Added reset for better control
    input  [DATA_WIDTH-1:0] stage_in,
    output [DATA_WIDTH-1:0] stage_out
);
    // Internal pipeline signals
    wire [DATA_WIDTH-1:0] registered_data;
    
    // Input pipeline stage with reset capability
    RegisterStage #(
        .DATA_WIDTH(DATA_WIDTH)
    ) input_stage (
        .clk        (clk),
        .rst_n      (rst_n),
        .data_in    (stage_in),
        .data_out   (registered_data)
    );
    
    // Configurable logic operation stage
    LogicOperationStage #(
        .DATA_WIDTH(DATA_WIDTH),
        .OPERATION_TYPE("NOT")  // Parameterized operation type
    ) logic_stage (
        .data_in    (registered_data),
        .data_out   (stage_out)
    );
    
endmodule

// Enhanced register stage with reset and clock enable support
module RegisterStage #(
    parameter DATA_WIDTH = 32
)(
    input                   clk,
    input                   rst_n,
    input  [DATA_WIDTH-1:0] data_in,
    output [DATA_WIDTH-1:0] data_out
);
    // Registered input with asynchronous reset
    reg [DATA_WIDTH-1:0] data_reg;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_reg <= {DATA_WIDTH{1'b0}};
        else
            data_reg <= data_in;
    end
    
    assign data_out = data_reg;
endmodule

// Configurable logic operation module supporting multiple operations
module LogicOperationStage #(
    parameter DATA_WIDTH = 32,
    parameter OPERATION_TYPE = "NOT"  // Can be extended to other operations
)(
    input  [DATA_WIDTH-1:0] data_in,
    output [DATA_WIDTH-1:0] data_out
);
    // Operation selector based on parameter
    generate
        if (OPERATION_TYPE == "NOT") begin: gen_not_op
            assign data_out = ~data_in;
        end
        else if (OPERATION_TYPE == "BUFFER") begin: gen_buffer_op
            assign data_out = data_in;
        end
        // Additional operations can be added here
        else begin: gen_default_op
            assign data_out = ~data_in; // Default to NOT operation
        end
    endgenerate
endmodule