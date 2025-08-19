//SystemVerilog
module multiply_and_operator (
    input clk,               // Clock signal
    input rst_n,             // Active-low reset
    
    // Input interface
    input [7:0] a,           // First operand
    input [7:0] b,           // Second operand
    input valid_in,          // Data valid signal (was req)
    output ready_in,         // Ready to accept data (was ack)
    
    // Output interface
    output reg [15:0] product,       // Multiplication result
    output reg [7:0] and_result,     // Bitwise AND result
    output reg valid_out,            // Output data valid
    input ready_out           // Downstream module ready to accept
);

    // Internal signals
    reg ready_in_reg;
    wire data_transfer;
    
    // Handshake logic
    assign data_transfer = valid_in && ready_in_reg;
    assign ready_in = ready_in_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            product <= 16'b0;
            and_result <= 8'b0;
            valid_out <= 1'b0;
            ready_in_reg <= 1'b1;
        end else begin
            if (data_transfer) begin
                // Perform operations when valid data arrives and we're ready
                product <= a * b;
                and_result <= a & b;
                valid_out <= 1'b1;
                ready_in_reg <= 1'b0;  // Stop accepting new data until current is consumed
            end
            
            if (valid_out && ready_out) begin
                // Data has been accepted by downstream module
                valid_out <= 1'b0;
                ready_in_reg <= 1'b1;  // Ready to accept new data
            end
        end
    end

endmodule