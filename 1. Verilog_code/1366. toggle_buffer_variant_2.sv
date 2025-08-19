//SystemVerilog
module toggle_buffer (
    input wire clk,
    input wire toggle,
    input wire [15:0] data_in,
    input wire write_en,
    output reg [15:0] data_out
);
    reg [15:0] buffer_a, buffer_b;
    reg sel;
    reg sel_q;
    
    always @(posedge clk) begin
        // Toggle logic
        if (toggle)
            sel <= ~sel;
        
        // Write logic
        if (write_en) begin
            if (sel)
                buffer_a <= data_in;
            else
                buffer_b <= data_in;
        end
        
        // Register select signal for timing optimization
        sel_q <= sel;
        
        // Output selection directly from buffer registers
        // Moved combinational mux before the final output register
        data_out <= sel_q ? buffer_b : buffer_a;
    end
endmodule