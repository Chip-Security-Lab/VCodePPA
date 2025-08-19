//SystemVerilog
//IEEE 1364-2005 Verilog标准
// Top level module
module d_ff_reset_enable (
    input  wire clk,
    input  wire rst_n,
    input  wire en,
    input  wire d,
    output wire q
);
    // Internal signal - simplified design by removing unnecessary signal
    wire gated_data;
    
    // Optimized reset and enable logic combined with data path
    assign gated_data = en ? d : q;
    
    // Single flip-flop instance with synchronous reset
    data_storage u_data_storage (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(gated_data),
        .q(q)
    );
    
endmodule

// Data storage module with improved timing
module data_storage (
    input  wire clk,
    input  wire rst_n,
    input  wire data_in,
    output reg  q
);
    // Single always block with asynchronous reset
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            q <= 1'b0;
        else
            q <= data_in;
    end
endmodule