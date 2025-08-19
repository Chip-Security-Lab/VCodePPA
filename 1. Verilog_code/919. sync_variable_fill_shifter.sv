module sync_variable_fill_shifter (
    input                clk,
    input                rst,
    input      [7:0]     data_in,
    input      [2:0]     shift_val,
    input                shift_dir,  // 0: left, 1: right
    input                fill_bit,   // Value to fill vacant positions
    output reg [7:0]     data_out
);
    // Temporary variable for shift calculation
    reg [7:0] shifted;
    
    always @(*) begin
        if (shift_dir) begin
            // Right shift with variable fill
            shifted = {fill_bit ? {8{1'b1}} : 8'b0, data_in} >> shift_val;
        end else begin
            // Left shift with variable fill
            shifted = (data_in << shift_val) | (fill_bit ? ((1 << shift_val) - 1) : 0);
        end
    end
    
    // Register the output
    always @(posedge clk or posedge rst) begin
        if (rst) data_out <= 8'h00;
        else data_out <= shifted;
    end
endmodule