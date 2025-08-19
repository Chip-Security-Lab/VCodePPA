//SystemVerilog
module SyncRecoveryBasic #(parameter WIDTH=8) (
    input clk, rst_n, en,
    input [WIDTH-1:0] noisy_in,
    output [WIDTH-1:0] clean_out
);
    reg [WIDTH-1:0] retimed_data;
    
    // Move register from output to input path
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            retimed_data <= 0;
        else if (en) 
            retimed_data <= noisy_in;
    end
    
    // Clean output is directly driven by retimed data
    assign clean_out = retimed_data;
endmodule