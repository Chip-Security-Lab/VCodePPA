//SystemVerilog
// SystemVerilog
// Top level module for IVMU Error Feedback
// This module instantiates submodules to generate error code and valid flag.
module IVMU_ErrorFeedback_Top (
    input clk,          // Clock signal
    input err_irq,      // Incoming error interrupt request
    output [1:0] err_code, // Output error code
    output err_valid    // Output error valid flag
);

    // Internal signals to connect submodules to top-level outputs
    wire [1:0] err_code_w;
    wire err_valid_w;

    // Instantiate the submodule for generating the error valid flag
    IVMU_ErrorValidGenerator valid_gen (
        .clk(clk),
        .err_irq(err_irq),
        .err_valid(err_valid_w)
    );

    // Instantiate the submodule for generating the error code
    IVMU_ErrorCodeGenerator code_gen (
        .clk(clk),
        .err_irq(err_irq),
        .err_code(err_code_w)
    );

    // Connect submodule outputs to top-level outputs
    assign err_valid = err_valid_w;
    assign err_code = err_code_w;

endmodule

// SystemVerilog
// Submodule to generate the error valid flag
// Registers the err_irq input to produce the err_valid output.
module IVMU_ErrorValidGenerator (
    input clk,          // Clock signal
    input err_irq,      // Incoming error interrupt request
    output reg err_valid    // Output error valid flag
);

    // Register the incoming error interrupt request for the valid flag
    always @(posedge clk) begin
        err_valid <= err_irq;
    end

endmodule

// SystemVerilog
// Submodule to generate the error code
// Formats and registers the err_irq input into a 2-bit error code.
module IVMU_ErrorCodeGenerator (
    input clk,          // Clock signal
    input err_irq,      // Incoming error interrupt request
    output reg [1:0] err_code // Output error code
);

    // Format and register the error interrupt request into a 2-bit error code
    always @(posedge clk) begin
        err_code <= {err_irq, 1'b0};
    end

endmodule