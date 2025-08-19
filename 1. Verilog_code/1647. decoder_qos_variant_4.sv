//SystemVerilog
module decoder_qos #(BURST_SIZE=4) (
    input clk, rst,
    input [3:0] req,
    output reg [3:0] grant
);
    reg [1:0] counter;
    wire [3:0] shifted_req;
    
    // Parallel prefix adder implementation for counter increment
    wire [1:0] counter_plus_1;
    wire [1:0] counter_plus_1_carry;
    
    // Generate and Propagate signals
    wire [1:0] G, P;
    assign G[0] = counter[0];
    assign P[0] = 1'b1;
    assign G[1] = counter[1] & counter[0];
    assign P[1] = counter[1] | counter[0];
    
    // Carry computation
    assign counter_plus_1_carry[0] = G[0];
    assign counter_plus_1_carry[1] = G[1] | (P[1] & G[0]);
    
    // Sum computation
    assign counter_plus_1[0] = counter[0] ^ 1'b1;
    assign counter_plus_1[1] = counter[1] ^ counter_plus_1_carry[0];
    
    // Barrel shifter implementation
    assign shifted_req[0] = (counter == 2'b00) ? req[0] : 
                           (counter == 2'b01) ? req[3] : 
                           (counter == 2'b10) ? req[2] : req[1];
                           
    assign shifted_req[1] = (counter == 2'b00) ? req[1] : 
                           (counter == 2'b01) ? req[0] : 
                           (counter == 2'b10) ? req[3] : req[2];
                           
    assign shifted_req[2] = (counter == 2'b00) ? req[2] : 
                           (counter == 2'b01) ? req[1] : 
                           (counter == 2'b10) ? req[0] : req[3];
                           
    assign shifted_req[3] = (counter == 2'b00) ? req[3] : 
                           (counter == 2'b01) ? req[2] : 
                           (counter == 2'b10) ? req[1] : req[0];
    
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            counter <= 0;
            grant <= 0;
        end else begin
            counter <= (counter == BURST_SIZE-1) ? 0 : counter_plus_1;
            grant <= shifted_req;
        end
    end
endmodule