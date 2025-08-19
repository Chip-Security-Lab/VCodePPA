//SystemVerilog
module priority_encoded_shifter(
    input wire clk,           // Added clock for pipelining
    input wire rst_n,         // Added reset signal
    input wire [7:0] data,
    input wire [2:0] priority_shift,
    output reg [7:0] result
);
    // Pipeline stage 1: Priority encoding
    reg [2:0] encoded_shift_amount;
    reg [7:0] data_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            encoded_shift_amount <= 3'b000;
            data_reg <= 8'b0;
        end else begin
            data_reg <= data;
            
            // Priority encoder with clearer structure
            if (priority_shift[2])      encoded_shift_amount <= 3'd4; // Highest priority: shift by 4
            else if (priority_shift[1]) encoded_shift_amount <= 3'd2; // Medium priority: shift by 2
            else if (priority_shift[0]) encoded_shift_amount <= 3'd1; // Lowest priority: shift by 1
            else                        encoded_shift_amount <= 3'd0; // No shift
        end
    end
    
    // Pipeline stage 2: Shifting operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result <= 8'b0;
        end else begin
            result <= data_reg << encoded_shift_amount;
        end
    end
endmodule