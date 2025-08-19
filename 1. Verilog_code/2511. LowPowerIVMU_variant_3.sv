//SystemVerilog
module LowPowerIVMU (
    input main_clk, rst_n,
    input [15:0] int_sources,
    input [15:0] int_mask,
    input clk_en,
    output reg [31:0] vector_out,
    output reg int_pending
);
    wire gated_clk;
    reg [31:0] vectors [0:15];
    wire [15:0] pending;
    integer i;

    // Signals for lookup table implementation
    wire pending_any;
    reg [3:0] lsb_index; // Index of the least significant bit set in 'pending'

    // Original assignments
    assign gated_clk = main_clk & (clk_en | |pending);
    assign pending = int_sources & ~int_mask;

    // Initialize the vectors array (acts as the lookup table)
    initial begin
        for (i = 0; i < 16; i = i + 1) begin
            vectors[i] = 32'h9000_0000 + (i * 4);
        end
    end

    // Combinatorial logic to find the LSB index and check if any bit is pending
    assign pending_any = |pending;

    always @(*) begin
        // Find the index of the least significant bit that is set
        if (pending[0]) lsb_index = 4'd0;
        else if (pending[1]) lsb_index = 4'd1;
        else if (pending[2]) lsb_index = 4'd2;
        else if (pending[3]) lsb_index = 4'd3;
        else if (pending[4]) lsb_index = 4'd4;
        else if (pending[5]) lsb_index = 4'd5;
        else if (pending[6]) lsb_index = 4'd6;
        else if (pending[7]) lsb_index = 4'd7;
        else if (pending[8]) lsb_index = 4'd8;
        else if (pending[9]) lsb_index = 4'd9;
        else if (pending[10]) lsb_index = 4'd10;
        else if (pending[11]) lsb_index = 4'd11;
        else if (pending[12]) lsb_index = 4'd12;
        else if (pending[13]) lsb_index = 4'd13;
        else if (pending[14]) lsb_index = 4'd14;
        else if (pending[15]) lsb_index = 4'd15;
        else lsb_index = 4'd0; // Default value when pending_any is 0 (index doesn't matter)
    end

    // Sequential logic updated to use the calculated index
    always @(posedge gated_clk or negedge rst_n) begin
        if (!rst_n) begin
            vector_out <= 32'h0;
            int_pending <= 1'b0;
        end else begin
            int_pending <= pending_any; // Update int_pending based on pending_any
            if (pending_any) begin
                // Use the LSB index to lookup the corresponding vector
                vector_out <= vectors[lsb_index];
            end
            // If pending_any is 0, vector_out retains its previous value.
        end
    end

endmodule