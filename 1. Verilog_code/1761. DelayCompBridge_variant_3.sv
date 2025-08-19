//SystemVerilog
module DelayCompBridge #(
    parameter DELAY_CYC = 3
)(
    input clk, rst_n,
    input [31:0] data_in,
    output [31:0] data_out
);
    // Main delay chain registers
    reg [31:0] delay_chain [0:DELAY_CYC-1];
    
    // Fan-out buffer for loop index to reduce fan-out load
    reg [1:0] i_buf1, i_buf2;
    
    // Fan-out buffers for delay_chain access
    reg [31:0] delay_chain_buf1, delay_chain_buf2;
    
    integer i;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Buffer the loop index to reduce fan-out
            i_buf1 <= 0;
            i_buf2 <= 0;
            
            // Reset all delay chain registers
            for (i = 0; i < DELAY_CYC; i = i + 1) 
                delay_chain[i] <= 0;
                
            // Reset buffer registers
            delay_chain_buf1 <= 0;
            delay_chain_buf2 <= 0;
        end else begin
            // Input stage buffering
            delay_chain[0] <= data_in;
            
            // Buffer the intermediate values to reduce fan-out load
            delay_chain_buf1 <= delay_chain[0];
            delay_chain_buf2 <= delay_chain[1];
            
            // Use buffered values for subsequent stages
            delay_chain[1] <= delay_chain_buf1;
            if (DELAY_CYC > 2)
                delay_chain[2] <= delay_chain_buf2;
                
            // Handle any remaining stages if DELAY_CYC > 3
            for (i = 3; i < DELAY_CYC; i = i + 1)
                delay_chain[i] <= delay_chain[i-1];
        end
    end
    
    // Additional registers added for optimization
    reg [31:0] delay_chain_buf3;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            delay_chain_buf3 <= 0;
        end else begin
            if (DELAY_CYC > 3)
                delay_chain_buf3 <= delay_chain[2]; // Buffering the output of the second stage
        end
    end
    
    assign data_out = (DELAY_CYC > 3) ? delay_chain_buf3 : delay_chain[DELAY_CYC-1];
endmodule