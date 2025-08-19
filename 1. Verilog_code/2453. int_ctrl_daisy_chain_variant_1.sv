//SystemVerilog
module int_ctrl_daisy_chain #(parameter CHAIN=4)(
    input clk, ack_in,
    output ack_out,
    input [CHAIN-1:0] int_req,
    output reg [CHAIN-1:0] int_ack
);
    // Register the input requests to improve timing
    reg [CHAIN-1:0] int_req_reg;
    
    // Registered ack chain with direct connection to ack_in
    reg [CHAIN-2:0] ack_chain_partial;
    wire [CHAIN-1:0] ack_chain;
    
    // Construct complete ack_chain with registered parts and direct ack_in
    assign ack_chain = {ack_chain_partial, ack_in};
    
    // Apply masking operation to registered request signals
    wire [CHAIN-1:0] masked_req;
    assign masked_req = ack_chain & int_req_reg;
    
    // Register input request signals to improve timing
    always @(posedge clk) begin
        int_req_reg <= int_req;
    end
    
    // Update the partial ack chain - moved register backward
    always @(posedge clk) begin
        ack_chain_partial <= ack_chain[CHAIN-1:1];
    end
    
    // Output acknowledgment signals
    always @(posedge clk) begin
        int_ack <= masked_req;
    end
    
    // Move OR operation before register for ack_out
    reg ack_out_reg;
    assign ack_out = ack_out_reg;
    
    always @(posedge clk) begin
        ack_out_reg <= |int_req;
    end
    
    // Initialization logic
    initial begin
        int_req_reg = {CHAIN{1'b0}};
        ack_chain_partial = {(CHAIN-1){1'b0}};
        int_ack = {CHAIN{1'b0}};
        ack_out_reg = 1'b0;
    end
endmodule