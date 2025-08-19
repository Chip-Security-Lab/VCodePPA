//SystemVerilog
module ripple_counter (
    input wire clk, rst_n,
    output reg [3:0] q
);
    reg [3:0] counter;
    wire [3:0] next_counter;
    wire [3:0] gray_code;
    
    // Calculate next counter value
    assign next_counter = counter + 4'b0001;
    
    // Gray code conversion logic
    assign gray_code[3] = next_counter[3];
    assign gray_code[2] = next_counter[3] ^ next_counter[2];
    assign gray_code[1] = next_counter[2] ^ next_counter[1];
    assign gray_code[0] = next_counter[1] ^ next_counter[0];
    
    // Counter update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 4'b0000;
            q <= 4'b0000;
        end else begin
            counter <= next_counter;
            q <= gray_code;
        end
    end
endmodule