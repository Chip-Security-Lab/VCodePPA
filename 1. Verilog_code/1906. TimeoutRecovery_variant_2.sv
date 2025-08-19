//SystemVerilog
module TimeoutRecovery #(parameter WIDTH=8, TIMEOUT=32'hFFFF) (
    input clk, rst_n,
    input [WIDTH-1:0] unstable_in,
    output reg [WIDTH-1:0] stable_out,
    output reg timeout
);
    reg [31:0] counter;
    wire [31:0] counter_next;
    wire counter_reset;
    wire timeout_condition;
    wire [31:0] counter_plus_one;
    wire [31:0] borrow_chain;
    
    // Detection for input change
    assign counter_reset = (unstable_in != stable_out);
    
    // Timeout condition check
    assign timeout_condition = (counter >= TIMEOUT);
    
    // Borrow-based incrementer implementation
    assign borrow_chain[0] = 1'b1; // Initial borrow-in for LSB
    
    genvar i;
    generate
        for (i = 0; i < 31; i = i + 1) begin : borrow_gen
            assign counter_plus_one[i] = counter[i] ^ borrow_chain[i];
            assign borrow_chain[i+1] = ~counter[i] & borrow_chain[i];
        end
    endgenerate
    
    // MSB handling
    assign counter_plus_one[31] = counter[31] ^ borrow_chain[31];
    
    // Counter next value selection
    assign counter_next = counter_reset ? 32'b0 : counter_plus_one;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 32'b0;
            stable_out <= {WIDTH{1'b0}};
            timeout <= 1'b0;
        end else begin
            counter <= counter_next;
            timeout <= timeout_condition;
            stable_out <= timeout_condition ? stable_out : unstable_in;
        end
    end
endmodule