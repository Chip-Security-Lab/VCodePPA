//SystemVerilog
module AsyncNor(
    input  logic clk,
    input  logic rst,
    // Input interface
    input  logic a,
    input  logic b,
    input  logic valid_in,  // New valid signal for input
    output logic ready_in,  // New ready signal for input
    // Output interface
    output logic y,
    output logic valid_out, // New valid signal for output
    input  logic ready_out  // New ready signal for output
);
    // Internal signals
    logic nor_result;
    logic data_valid;      // Tracks if we have valid data in the pipeline
    logic input_accepted;  // Indicates when input data is accepted
    
    // Input handshake control
    assign input_accepted = valid_in && ready_in;
    assign ready_in = !data_valid || (data_valid && ready_out); // Ready when pipeline is empty or output is accepting
    
    // First stage - input capture and NOR operation
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            nor_result <= 1'b0;
            data_valid <= 1'b0;
        end else if (ready_in && valid_in) begin
            nor_result <= ~(a | b);
            data_valid <= 1'b1;
        end else if (ready_out && valid_out) begin
            data_valid <= 1'b0; // Clear valid flag once output is accepted
        end
    end
    
    // Output control
    assign valid_out = data_valid;
    
    // Output value update
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            y <= 1'b0;
        end else if (data_valid && ready_out) begin
            y <= nor_result;
        end
    end
endmodule