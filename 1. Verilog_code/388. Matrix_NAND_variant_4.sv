//SystemVerilog - IEEE 1364-2005
module Matrix_NAND(
    input clk,
    input rst_n,
    // Input interface
    input [3:0] row,
    input [3:0] col,
    input valid_in,
    output reg ready_in,
    
    // Output interface
    output reg [7:0] mat_res,
    output reg valid_out,
    input ready_out
);
    // Internal registers
    reg [7:0] result_reg;
    reg valid_pending;
    
    // Reset logic
    always @(negedge rst_n) begin
        if (!rst_n) begin
            result_reg <= 8'h0;
            valid_pending <= 1'b0;
            valid_out <= 1'b0;
            ready_in <= 1'b1;
            mat_res <= 8'h0;
        end
    end
    
    // Input processing logic
    always @(posedge clk) begin
        if (rst_n) begin
            // Handle input acceptance
            if (valid_in && ready_in) begin
                result_reg <= ~({row, col} & 8'hAA);
                valid_pending <= 1'b1;
                ready_in <= 1'b0; // Not ready for new input until current output is accepted
            end
        end
    end
    
    // Output processing logic
    always @(posedge clk) begin
        if (rst_n) begin
            // Handle output transfer
            if (valid_pending && !valid_out) begin
                valid_out <= 1'b1;
                mat_res <= result_reg;
            end else if (valid_out && ready_out) begin
                valid_out <= 1'b0;
                valid_pending <= 1'b0;
                ready_in <= 1'b1; // Ready for new input after output is accepted
            end
        end
    end
endmodule